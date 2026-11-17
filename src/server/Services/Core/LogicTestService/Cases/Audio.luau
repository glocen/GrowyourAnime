--!strict
-- Audio cases (pure): the level check's measure (ServerStorage.NL_Tools.Audio.Loudness; docs/asset-requests.md, AR8 A)
-- reads what ITU-R BS.1770-4 says it should, and a batch's measures (NL_Tools.Audio.Measures; AR39) read what numpy
-- reads, on signals whose answers are known.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Loudness = require(game:GetService("ServerStorage").NL_Tools.Audio.Loudness)
local Measures = require(game:GetService("ServerStorage").NL_Tools.Audio.Measures)

local function sine(rate: number, seconds: number, hz: number, amplitude: number, phase: number?): { number }
	local out = table.create(math.floor(rate * seconds), 0)
	for i = 1, #out do
		out[i] = amplitude * math.sin(2 * math.pi * hz * (i - 1) / rate + (phase or 0))
	end
	return out
end

return {
	{
		Name = "Audio: the level check measures as BS.1770 says",
		Run = function(t: any)
			-- the standard's own table at 48 kHz (BS.1770-4, tables 1 and 2)
			local shelf, pass = Loudness.KWeighting(48000)
			local function near(a: number, b: number): boolean
				return math.abs(a - b) < 1e-6
			end
			t.Check("the shelf at 48 kHz, the standard's", near(shelf.B0, 1.53512485958697) and near(shelf.B1, -2.69169618940638) and near(shelf.B2, 1.19839281085285) and near(shelf.A1, -1.69065929318241) and near(shelf.A2, 0.73248077421585), string.format("%.8f %.8f", shelf.B0, shelf.A1))
			t.Check("the high pass at 48 kHz, the standard's", near(pass.A1, -1.99004745483398) and near(pass.A2, 0.99007225036621), string.format("%.8f %.8f", pass.A1, pass.A2))
			-- a 997 Hz sine at full scale on one channel reads -3.01 LUFS, at any rate; 20 dB down reads 20 LU less
			for _, rate in { 48000, 32000 } do
				local full = Loudness.Measure(sine(rate, 3, 997, 1), rate)
				t.Check(`{rate} Hz: a full-scale 997 Hz sine, -3.01 LUFS`, math.abs(full.Integrated + 3.01) < 0.05, string.format("%.3f", full.Integrated))
				t.Check(`{rate} Hz: its momentary and short-term the same`, math.abs(full.Momentary + 3.01) < 0.05 and math.abs(full.ShortTerm + 3.01) < 0.05, string.format("%.3f %.3f", full.Momentary, full.ShortTerm))
				local low = Loudness.Measure(sine(rate, 3, 997, 0.1), rate)
				t.Check(`{rate} Hz: 20 dB down, -23.01 LUFS`, math.abs(low.Integrated + 23.01) < 0.05, string.format("%.3f", low.Integrated))
			end
			-- silence doesn't pull the integrated level down: the absolute gate
			local rate = 48000
			local tone = sine(rate, 2, 997, 0.1)
			for _ = 1, 2 * rate do
				table.insert(tone, 0)
			end
			local gated = Loudness.Measure(tone, rate)
			-- the silence's blocks are gated out; the three across the edge (3/4, 1/2 and 1/4 tone) pass both gates, as the
			-- standard has it, so the 20 blocks hold 18.5 blocks' energy
			local want = -23.01 + 10 * math.log10(18.5 / 20)
			t.Check("2 s of tone and 2 of silence: the tone's level, the silence gated", math.abs(gated.Integrated - want) < 0.05, string.format("%.3f, want %.3f", gated.Integrated, want))
			t.Check("the short-term over the silence reads lower", gated.ShortTerm < gated.Momentary)
			-- a quarter-rate sine sampled off its crests: samples at -3.01 dB, its true peak at 0
			local off = sine(rate, 0.2, rate / 4, 1, math.pi / 4)
			local peak = Loudness.Measure(off, rate)
			t.Check("the sample peak misses the crest", math.abs(peak.SamplePeak + 3.01) < 0.02, string.format("%.3f", peak.SamplePeak))
			t.Check("the true peak finds it", math.abs(peak.TruePeak) < 0.2, string.format("%.3f", peak.TruePeak))
			-- nothing at all
			local quiet = Loudness.Measure(table.create(rate, 0), rate)
			t.Check("silence: no level and no peak", quiet.Integrated == -math.huge and quiet.TruePeak == -math.huge)
		end,
	},
	{
		Name = "Audio: a batch's measures read as numpy reads them (AR39; tools/audio/ar39_rank.py's own definitions)",
		Run = function(t: any)
			-- a decaying 440 Hz tone over a steady 3150 Hz one, 20 ms of silence before and 100 ms after; the answers are
			-- numpy's, on the same signal (np.fft.rfft, np.hanning), to 0.01 dB
			local rate = 48000
			local function near(a: number, b: number, within: number?): boolean
				return math.abs(a - b) < (within or 0.01)
			end
			for _, case in {
				{ Length = 7200, Env = 135, Frames = 27, Spec10 = 51.4240, Spec19 = 55.3851, Out = 0.103804 },
				{ Length = 14400, Env = 210, Frames = 42, Spec10 = 46.0511, Spec19 = 55.9458, Out = 0.102372 }, -- Welch's segments
			} do
				local window = table.create(960 + case.Length + 4800, 0)
				for n = 0, case.Length - 1 do
					window[961 + n] = 0.6 * math.sin(2 * math.pi * 440 * n / rate) * math.exp(-n / 2400) + 0.25 * math.sin(2 * math.pi * 3150 * n / rate)
				end
				local m = Measures.Slice(window, rate, 960, case.Length)
				local at = `{case.Length} samples:`
				t.Check(`{at} the envelope, 2 ms a step from 20 ms ahead`, #m.Envelope == case.Env and near(m.Envelope[11], -6.6078) and near(m.Envelope[40], -13.1000), `{#m.Envelope} {m.Envelope[11]} {m.Envelope[40]}`)
				local third = m.Spectrogram[3]
				t.Check(`{at} the spectrogram, 10 ms a frame, by third octaves`, #m.Spectrogram == case.Frames and #third == 25 and near(third[10], 47.2007) and near(third[19], 43.6156) and near(m.Spectrogram[9][1], -21.8449), `{#m.Spectrogram} {third[10]} {third[19]} {m.Spectrogram[9][1]}`)
				t.Check(`{at} the slice's averaged spectrum`, near(m.Spectrum[10], case.Spec10) and near(m.Spectrum[19], case.Spec19), `{m.Spectrum[10]} {m.Spectrum[19]}`)
				t.Check(`{at} the sample peak and its time`, near(m.SamplePeak, -1.9820) and near(m.SamplePeakAt, 0.000708, 1e-5), `{m.SamplePeak} {m.SamplePeakAt}`)
				t.Check(`{at} the steps in the first and last 3 ms`, near(m.StepIn, 0.135858, 1e-5) and near(m.StepOut, case.Out, 1e-5), `{m.StepIn} {m.StepOut}`)
				t.Check(`{at} a loudness and a true peak`, m.Loudness > -20 and m.Loudness < 0 and m.TruePeak >= m.SamplePeak - 1e-9, `{m.Loudness} {m.TruePeak}`)
			end
			-- a 60 Hz tone with a little 1 kHz: its weight under 120 Hz
			local low = table.create(7200, 0)
			for n = 0, 7199 do
				low[n + 1] = 0.5 * math.sin(2 * math.pi * 60 * n / rate) + 0.05 * math.sin(2 * math.pi * 1000 * n / rate)
			end
			local m = Measures.Slice(low, rate, 0, 7200)
			t.Check("a 60 Hz tone: 99% of it under 120 Hz", near(m.Under120, 0.990099, 1e-5) and near(m.Spectrum[1], 51.8218) and near(m.Spectrum[14], 41.4057), `{m.Under120} {m.Spectrum[1]} {m.Spectrum[14]}`)
		end,
	},
}
