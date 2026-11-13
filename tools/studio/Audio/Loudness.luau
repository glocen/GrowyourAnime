--!strict
-- Loudness (pure): a signal's loudness by ITU-R BS.1770-4 (EBU R 128's measure) and its true peak, at any sample rate,
-- for the level check (Mixdown; docs/asset-requests.md, AR8 A). It runs with Studio closed, so its cases are in
-- LogicTestService/Cases/Audio.luau.
--   K-weighting: the standard's two filters, a high shelf and a high pass, designed for the rate as libebur128 does.
--   Momentary: 400 ms windows, short-term: 3 s, both stepped every 100 ms; integrated: 400 ms blocks at 75% overlap,
--   gated at -70 LUFS and then 10 LU under the gated mean.
--   True peak: 4x oversampled by a windowed sinc, 12 taps a phase (the standard's annex 2 asks at least 4x).
-- One channel: a mono signal reads as a single channel, so a centred sound on two speakers would read 3 LU higher. Every
-- cue is read the same way, so differences between mixes hold.

local Loudness = {}

export type Measure = {
	Integrated: number, -- LUFS, gated; -math.huge when every block is under the absolute gate
	Momentary: number, -- the loudest 400 ms, LUFS
	ShortTerm: number, -- the loudest 3 s, LUFS (the whole signal when it's shorter)
	TruePeak: number, -- dBTP
	SamplePeak: number, -- dBFS
	Seconds: number,
}

type Biquad = { B0: number, B1: number, B2: number, A1: number, A2: number }

local function db(linear: number): number
	return if linear > 0 then 20 * math.log10(linear) else -math.huge
end

local function lufs(meanSquare: number): number
	return if meanSquare > 0 then -0.691 + 10 * math.log10(meanSquare) else -math.huge
end

-- The standard's two stages at `rate` (libebur128's design, which matches the standard's 48 kHz table).
function Loudness.KWeighting(rate: number): (Biquad, Biquad)
	local f0, gain, q = 1681.974450955533, 3.999843853973347, 0.7071752369554196
	local k = math.tan(math.pi * f0 / rate)
	local vh = 10 ^ (gain / 20)
	local vb = vh ^ 0.4996667741545416
	local a0 = 1 + k / q + k * k
	local shelf: Biquad = {
		B0 = (vh + vb * k / q + k * k) / a0,
		B1 = 2 * (k * k - vh) / a0,
		B2 = (vh - vb * k / q + k * k) / a0,
		A1 = 2 * (k * k - 1) / a0,
		A2 = (1 - k / q + k * k) / a0,
	}
	f0, q = 38.13547087602444, 0.5003270373238773
	k = math.tan(math.pi * f0 / rate)
	local a = 1 + k / q + k * k
	local pass: Biquad = { B0 = 1, B1 = -2, B2 = 1, A1 = 2 * (k * k - 1) / a, A2 = (1 - k / q + k * k) / a }
	return shelf, pass
end

local function run(f: Biquad, x: { number }): { number }
	local y = table.create(#x, 0)
	local x1, x2, y1, y2 = 0, 0, 0, 0
	local b0, b1, b2, a1, a2 = f.B0, f.B1, f.B2, f.A1, f.A2
	for i = 1, #x do
		local v = x[i]
		local out = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
		x2, x1, y2, y1 = x1, v, y1, out
		y[i] = out
	end
	return y
end

-- The signal K-weighted, squared, and summed so any window's mean square is two reads.
local function energy(samples: { number }, rate: number): { number }
	local shelf, pass = Loudness.KWeighting(rate)
	local weighted = run(pass, run(shelf, samples))
	local sum = table.create(#weighted + 1, 0)
	local total = 0
	for i, v in weighted do
		total += v * v
		sum[i + 1] = total
	end
	return sum
end

-- The mean square of each `seconds` window stepped every `step` seconds; one window over the whole when it's shorter.
local function windows(sum: { number }, rate: number, seconds: number, step: number): { number }
	local count = #sum - 1
	local size = math.floor(seconds * rate + 0.5)
	local out: { number } = {}
	if count <= 0 then
		return out
	end
	if size >= count then
		table.insert(out, sum[count + 1] / count)
		return out
	end
	local hop = math.max(1, math.floor(step * rate + 0.5))
	for start = 0, count - size, hop do
		table.insert(out, (sum[start + size + 1] - sum[start + 1]) / size)
	end
	return out
end

-- Gated integrated loudness from 400 ms blocks' mean squares (BS.1770-4, section 2.8).
local function integrated(blocks: { number }): number
	local function meanOver(gate: number): number?
		local total, n = 0, 0
		for _, z in blocks do
			if lufs(z) > gate then
				total += z
				n += 1
			end
		end
		return if n > 0 then total / n else nil
	end
	local absolute = meanOver(-70)
	if absolute == nil then
		return -math.huge
	end
	local relative = meanOver(lufs(absolute) - 10)
	return lufs(relative or absolute)
end

-- The 4x oversampler's three in-between phases: a sinc 6 samples each side, Hann-windowed, each phase summing to 1.
local HALF = 6
local PHASES: { { number } } = {}
for p = 1, 3 do
	local frac = p / 4
	local row: { number } = {}
	local total = 0
	for j = -HALF + 1, HALF do
		local t = frac - j
		local sinc = if math.abs(t) < 1e-12 then 1 else math.sin(math.pi * t) / (math.pi * t)
		local w = 0.5 * (1 + math.cos(math.pi * t / HALF))
		row[j + HALF] = sinc * w
		total += sinc * w
	end
	for i, v in row do
		row[i] = v / total
	end
	PHASES[p] = row
end

-- The true peak, dBTP: the samples and three points between each pair, interpolated.
function Loudness.TruePeak(samples: { number }): number
	local n = #samples
	local most = 0
	for i = 1, n do
		local v = math.abs(samples[i])
		if v > most then
			most = v
		end
	end
	for i = 1, n - 1 do
		-- only where a peak could hide: next to a sample within 4 dB of the loudest so far
		local here, nextOne = math.abs(samples[i]), math.abs(samples[i + 1])
		if math.max(here, nextOne) * 1.6 < most then
			continue
		end
		for p = 1, 3 do
			local row = PHASES[p]
			local v = 0
			for j = -HALF + 1, HALF do
				local k = i + j
				if k >= 1 and k <= n then
					v += samples[k] * row[j + HALF]
				end
			end
			v = math.abs(v)
			if v > most then
				most = v
			end
		end
	end
	return db(most)
end

function Loudness.SamplePeak(samples: { number }): number
	local most = 0
	for _, v in samples do
		most = math.max(most, math.abs(v))
	end
	return db(most)
end

function Loudness.Measure(samples: { number }, rate: number): Measure
	local sum = energy(samples, rate)
	local momentary, short = -math.huge, -math.huge
	for _, z in windows(sum, rate, 0.4, 0.1) do
		momentary = math.max(momentary, lufs(z))
	end
	for _, z in windows(sum, rate, 3, 0.1) do
		short = math.max(short, lufs(z))
	end
	return {
		Integrated = integrated(windows(sum, rate, 0.4, 0.1)),
		Momentary = momentary,
		ShortTerm = short,
		TruePeak = Loudness.TruePeak(samples),
		SamplePeak = Loudness.SamplePeak(samples),
		Seconds = #samples / rate,
	}
end

return Loudness
