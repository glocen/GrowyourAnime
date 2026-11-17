--!strict
-- Measures (pure): a library slice's numbers, for a teammate who ranks sounds without hearing them (AR39, "The briefs,
-- and the first batch"). Never audio, only these, read the way tools/audio/ar39_rank.py's self-test measures our own
-- takes, so the ranker reads a batch and its self-test alike. Batch reads the windows in Studio; the cases are in
-- LogicTestService/Cases/Audio.luau.
--   The window: from Before ahead of the slice's start to After past its end.
--   Envelope: RMS in dBFS per Step, full steps from the window's start.
--   Spectrogram: per Frame from the window's start, Hann-windowed (numpy's symmetric hanning), zero-padded to a Size-point
--   FFT, each third-octave band's power summed, dB. The bands: centres 50 Hz × 2^(k/3), k = 0..24 (50 Hz to 12.7 kHz),
--   edges a sixth of an octave each side.
--   Spectrum: the slice's own power, averaged by Welch's method (Size-point Hann segments at half overlap, the last one
--   set at the slice's end; a slice shorter than Size is one zero-padded segment), banded the same way.
--   Under120: that averaged power's share under 120 Hz.
--   Loudness: the loudest 400 ms, K-weighted (Loudness's Momentary); a slice shorter than 400 ms is padded with silence.
--   SamplePeak in dBFS and SamplePeakAt in seconds after the slice's start; StepIn and StepOut: the largest step between
--   two samples in the slice's first and last Edge (linear).

local Loudness = require(game:GetService("ServerStorage").NL_Tools.Audio.Loudness) -- by its place: a clone has no parent

local SIZE, BITS = 8192, 13
local BAND_FLOOR = 1e-12 -- power added before dB, as the ranker's self-test does
local RMS_FLOOR = 1e-9

local Measures = {}

Measures.Before, Measures.After = 0.02, 0.1 -- seconds
Measures.Step, Measures.Frame, Measures.Edge = 0.002, 0.01, 0.003 -- seconds
Measures.Size = SIZE
Measures.Centres = {} :: { number }
for k = 0, 24 do
	Measures.Centres[k + 1] = 50 * 2 ^ (k / 3)
end

export type Slice = {
	Envelope: { number }, -- dBFS per Step
	Spectrogram: { { number } }, -- per Frame, dB per band
	Spectrum: { number }, -- dB per band
	Under120: number, -- 0..1
	Loudness: number, -- LUFS
	TruePeak: number, -- dBTP
	SamplePeak: number, -- dBFS
	SamplePeakAt: number, -- seconds after the slice's start
	StepIn: number,
	StepOut: number,
}

local reversed: { number } = table.create(SIZE, 0)
local cosines: { number } = table.create(SIZE // 2, 0)
local sines: { number } = table.create(SIZE // 2, 0)
for i = 0, SIZE - 1 do
	local r, x = 0, i
	for _ = 1, BITS do
		r = r * 2 + x % 2
		x = x // 2
	end
	reversed[i + 1] = r + 1
end
for k = 0, SIZE // 2 - 1 do
	cosines[k + 1] = math.cos(2 * math.pi * k / SIZE)
	sines[k + 1] = -math.sin(2 * math.pi * k / SIZE)
end

local hanns: { [number]: { number } } = {}
local function hann(n: number): { number }
	local kept = hanns[n]
	if kept then
		return kept
	end
	local w = table.create(n, 1)
	if n > 1 then
		for i = 0, n - 1 do
			w[i + 1] = 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1))
		end
	end
	hanns[n] = w
	return w
end

-- The power |X_k|² for k = 0..Size/2 of `count` samples from `from` (1-based) times `window`, zero-padded to Size.
function Measures.Power(samples: { number }, from: number, count: number, window: { number }?): { number }
	local re, im = table.create(SIZE, 0), table.create(SIZE, 0)
	for i = 1, math.min(count, SIZE) do
		re[reversed[i]] = (samples[from + i - 1] or 0) * (if window then window[i] else 1)
	end
	local size = 2
	while size <= SIZE do
		local half, step = size // 2, SIZE // size
		for start = 1, SIZE, size do
			local t = 1
			for j = start, start + half - 1 do
				local k = j + half
				local wr, wi = cosines[t], sines[t]
				local ar, ai = re[k], im[k]
				local tr, ti = wr * ar - wi * ai, wr * ai + wi * ar
				re[k], im[k] = re[j] - tr, im[j] - ti
				re[j], im[j] = re[j] + tr, im[j] + ti
				t += step
			end
		end
		size *= 2
	end
	local out = table.create(SIZE // 2 + 1, 0)
	for k = 1, SIZE // 2 + 1 do
		out[k] = re[k] * re[k] + im[k] * im[k]
	end
	return out
end

local binsByRate: { [number]: { { number } } } = {}
local function bins(rate: number): { { number } }
	local kept = binsByRate[rate]
	if kept then
		return kept
	end
	local out = {}
	for b, centre in Measures.Centres do
		local low, high = centre * 2 ^ (-1 / 6), centre * 2 ^ (1 / 6)
		local first, last = math.huge, -1
		for k = 0, SIZE // 2 do
			local f = k * rate / SIZE
			if f >= low and f < high then
				first, last = math.min(first, k), math.max(last, k)
			end
		end
		out[b] = { first + 1, last + 1 } -- 1-based; empty when last < first
	end
	binsByRate[rate] = out
	return out
end

-- Power per bin summed in each third-octave band, dB.
function Measures.Bands(power: { number }, rate: number): { number }
	local out = {}
	for b, range in bins(rate) do
		local total = 0
		for k = range[1], range[2] do
			total += power[k]
		end
		out[b] = 10 * math.log10(total + BAND_FLOOR)
	end
	return out
end

local function db(linear: number, floor: number): number
	return 20 * math.log10(math.max(linear, floor))
end

-- A slice's numbers. `window` holds the samples from Before ahead of the slice to After past it, `before` and `length`
-- are the samples ahead of the slice and in it. `pause`, if given, is called after each FFT (Studio passes task.wait).
function Measures.Slice(window: { number }, rate: number, before: number, length: number, pause: (() -> ())?): Slice
	local envelope = {}
	local hop = math.floor(Measures.Step * rate + 0.5)
	for i = 0, #window - hop, hop do
		local sum = 0
		for j = i + 1, i + hop do
			sum += window[j] * window[j]
		end
		table.insert(envelope, db(math.sqrt(sum / hop), RMS_FLOOR))
	end

	local spectrogram = {}
	local frame = math.floor(Measures.Frame * rate + 0.5)
	local frameWindow = hann(frame)
	for i = 0, #window - frame, frame do
		table.insert(spectrogram, Measures.Bands(Measures.Power(window, i + 1, frame, frameWindow), rate))
		if pause then
			pause()
		end
	end

	local slice = table.move(window, before + 1, before + length, 1, table.create(length, 0))
	local average = table.create(SIZE // 2 + 1, 0)
	local starts = {}
	if length <= SIZE then
		starts = { 1 }
	else
		for s = 1, length - SIZE + 1, SIZE // 2 do
			table.insert(starts, s)
		end
		if starts[#starts] + SIZE - 1 < length then
			table.insert(starts, length - SIZE + 1)
		end
	end
	local segment = math.min(length, SIZE)
	local segmentWindow = hann(segment)
	for _, s in starts do
		local power = Measures.Power(slice, s, segment, segmentWindow)
		for k, p in power do
			average[k] += p / #starts
		end
		if pause then
			pause()
		end
	end
	local under, total = 0, 0
	for k, p in average do
		total += p
		if (k - 1) * rate / SIZE < 120 then
			under += p
		end
	end

	local padded = table.clone(slice)
	for i = #padded + 1, math.ceil(0.4 * rate) do
		padded[i] = 0
	end
	local loud = Loudness.Measure(padded, rate)

	local most, at = 0, 1
	for i, v in slice do
		if math.abs(v) > most then
			most, at = math.abs(v), i
		end
	end
	local edge = math.floor(Measures.Edge * rate + 0.5)
	local function steps(first: number, last: number): number
		local largest = 0
		for i = math.max(first, 1), math.min(last, length) - 1 do
			largest = math.max(largest, math.abs(slice[i + 1] - slice[i]))
		end
		return largest
	end

	return {
		Envelope = envelope,
		Spectrogram = spectrogram,
		Spectrum = Measures.Bands(average, rate),
		Under120 = if total > 0 then under / total else 0,
		Loudness = loud.Momentary,
		TruePeak = loud.TruePeak,
		SamplePeak = db(most, RMS_FLOOR),
		SamplePeakAt = (at - 1) / rate,
		StepIn = steps(1, edge),
		StepOut = steps(length - edge + 1, length),
	}
end

return Measures
