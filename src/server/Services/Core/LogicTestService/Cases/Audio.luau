--!strict
-- Audio cases (pure): the level check's measure (ServerStorage.NL_Tools.Audio.Loudness; docs/asset-requests.md, AR8 A)
-- reads what ITU-R BS.1770-4 says it should, and a batch's measures (NL_Tools.Audio.Measures; AR39) read what numpy
-- reads, on signals whose answers are known.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Loudness = require(game:GetService("ServerStorage").NL_Tools.Audio.Loudness)
local Measures = require(game:GetService("ServerStorage").NL_Tools.Audio.Measures)
local CueMix = require(game:GetService("ServerStorage").NL_Tools.Audio.CueMix)
local Cues = require(game:GetService("ReplicatedStorage").Shared.Config.Cues)

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
	{
		Name = "Audio: a cue mixed as the engine plays it, and the gates' numbers on the mix (AR39; NL_Tools.Audio.CueMix)",
		Run = function(t: any)
			local rate = 48000
			local function near(a: number, b: number, within: number?): boolean
				return math.abs(a - b) < (within or 0.01)
			end
			local function flat(seconds: number, level: number): { number }
				return table.create(math.floor(rate * seconds), level)
			end
			local click = table.create(4800, 0)
			click[1441] = 0.8 -- 30 ms in
			local sounds: { [number]: { number } } = {
				[1] = sine(rate, 0.1, 1000, 0.25),
				[2] = sine(rate, 0.1, 1000, 0.25),
				[3] = click,
				[4] = flat(0.2, 0.5),
				[5] = sine(rate, 0.5, 60, 0.25),
			}
			local function source(take: Cues.Take): { number }?
				return sounds[take.Id]
			end
			local takes = Cues.Takes :: { [string]: any }
			takes.NL_MixTone = { { Id = 1, Seconds = 0.1, Peak = 0.01 }, { Id = 2, Seconds = 0.1, Peak = 0.01, Gain = 2 }, { Id = 99, Seconds = 0.1, Peak = 0 } }
			takes.NL_MixClick = { { Id = 3, Seconds = 0.1, Peak = 0.03 } }
			takes.NL_MixFlat = { { Id = 4, Seconds = 0.2, Peak = 0, From = 1, To = 1.2, In = 0.003, Out = 0.04 } }
			takes.NL_MixLow = { { Id = 5, Seconds = 0.5, Peak = 0 } }
			local function cue(layers: { any }): Cues.Cue
				return { Layers = layers, Bus = "Lead", Pitch = { 1, 1 }, Volume = { 1, 1 }, Voices = 4, Near = 30, Range = 160 }
			end
			local full = 1 / (Cues.Volume * Cues.Trim * CueMix.Engine.PlayerGain) -- a layer's volume that plays its file as it is
			local stepped = CueMix.Engine.Stepped
			local ok, problem = pcall(function()
				-- the level: a file as it is, a take's gain, a take that didn't load
				local tone = cue({ { Takes = "NL_MixTone", At = 0, Volume = full } })
				local plain = CueMix.Play({ Cue = tone, Takes = { 1 } }, source, rate)
				local m = CueMix.Measure(plain, rate)
				t.Check("a tone at a quarter of full scale reads -12.04 dBFS, from the lead's silence", near(m.SamplePeak, -12.041) and near(plain.Origin, -CueMix.Lead, 1e-9) and plain.Missed == 0, `{m.SamplePeak} {plain.Origin}`)
				t.Check("its top inside the tone, after the moment", m.PeakAt > 0 and m.PeakAt < 0.1, tostring(m.PeakAt))
				-- 0.1 s of a 1 kHz sine at 0.25, read over 3 s: -3.01 - 12.04 - 10 log10(30) = -29.82 LUFS
				t.Check("its short-term loudness: its energy over 3 s", near(m.ShortTerm, -29.82, 0.1), tostring(m.ShortTerm))
				t.Check("the phone's curve leaves 1 kHz as it is", near(m.Phone, m.ShortTerm, 0.1), tostring(m.Phone - m.ShortTerm))
				local louder = CueMix.Measure(CueMix.Play({ Cue = tone, Takes = { 2 } }, source, rate), rate)
				t.Check("a take's gain of 2 is 6.02 dB", near(louder.SamplePeak - m.SamplePeak, 6.0206), tostring(louder.SamplePeak - m.SamplePeak))
				local none = CueMix.Play({ Cue = tone, Takes = { 3 } }, source, rate)
				t.Check("a take that didn't load is counted, never mixed", none.Missed == 1 and CueMix.Measure(none, rate).SamplePeak < -100)
				t.Check("a take's number past its list wraps", near(CueMix.Measure(CueMix.Play({ Cue = tone, Takes = { 4 } }, source, rate), rate).SamplePeak, m.SamplePeak))
				local hot = CueMix.Play({ Cue = cue({ { Takes = "NL_MixTone", At = 0, Volume = full * 100 } }), Takes = { 1 } }, source, rate)
				t.Check("a player's volume stops at 3", hot.Clamped == 1 and near(CueMix.Measure(hot, rate).SamplePeak, 20 * math.log10(0.25 * 3 * CueMix.Engine.PlayerGain)))
				-- a layer led by its top lands it on the moment; a later layer keeps its place
				local led = CueMix.Measure(CueMix.Play({ Cue = cue({ { Takes = "NL_MixClick", At = 0, Lead = "Peak", Volume = full } }) }, source, rate), rate)
				t.Check("a layer led by its top: its top on the moment", near(led.PeakAt, 0, 1 / rate + 1e-9), tostring(led.PeakAt))
				local late = CueMix.Measure(CueMix.Play({ Cue = cue({ { Takes = "NL_MixClick", At = 0.05, Volume = full } }) }, source, rate), rate)
				t.Check("a layer 50 ms after the moment: its top 80 ms after", near(late.PeakAt, 0.08, 1 / rate + 1e-9), tostring(late.PeakAt))
				-- the edges: a slice's start isn't drawn (3 ms), its fall is a tween's steps
				local slice = cue({ { Takes = "NL_MixFlat", At = 0, Volume = full } })
				CueMix.Engine.Stepped = true
				local stairs = CueMix.Play({ Cue = slice }, source, rate)
				t.Check("a slice's 3 ms rise isn't drawn: it starts at its first sample, a step of its whole top", near(stairs.In, 1, 1e-6), tostring(stairs.In))
				t.Check("a tone that starts on its zero steps nothing in", plain.In < 1e-6, tostring(plain.In))
				local matched = CueMix.Measure(CueMix.Play({ Cue = tone, Takes = { 1 }, Gain = 2 }, source, rate), rate)
				t.Check("a play's gain of 2, the matched level's, is 6.02 dB", near(matched.SamplePeak - m.SamplePeak, 6.0206), tostring(matched.SamplePeak - m.SamplePeak))
				t.Check("a 40 ms fall in a frame's steps: each a frame's share of it", near(stairs.Fade, 0.5 * CueMix.Engine.Frame / 0.04, 1e-3), tostring(stairs.Fade))
				CueMix.Engine.Stepped = false
				local line = CueMix.Play({ Cue = slice }, source, rate)
				t.Check("the same fall as its straight line: no step", line.Fade < 0.001 and line.Out < 0.001, `{line.Fade} {line.Out}`)
				-- plays over each other
				local twice = CueMix.Measure(CueMix.Mix({ { Render = plain, At = 0 }, { Render = plain, At = 0 } }, rate), rate)
				t.Check("two plays on one sample: 6.02 dB over one", near(twice.SamplePeak - m.SamplePeak, 6.0206), tostring(twice.SamplePeak - m.SamplePeak))
				local apart = CueMix.Mix({ { Render = plain, At = 0 }, { Render = plain, At = 0.5 } }, rate)
				local spaced = CueMix.Measure(apart, rate)
				t.Check("two plays half a second apart: one's top, both's energy", near(spaced.SamplePeak, m.SamplePeak) and near(spaced.ShortTerm - m.ShortTerm, 3.0103, 0.05) and near(#apart.Samples / rate, 0.5 + #plain.Samples / rate, 0.001), `{spaced.ShortTerm - m.ShortTerm}`)
				-- the phone's curve: 60 Hz through a second-order high-pass at 200 falls by 0.09 / sqrt(1 + 0.0081), 20.95 dB
				local low = CueMix.Measure(CueMix.Play({ Cue = cue({ { Takes = "NL_MixLow", At = 0, Volume = full } }) }, source, rate), rate)
				t.Check("a 60 Hz tone through the phone's curve: 21 dB down, and nearly all under 120 Hz", near(low.Phone - low.ShortTerm, -20.95, 0.5) and low.Under120 > 0.95, `{low.Phone - low.ShortTerm} {low.Under120}`)
			end)
			CueMix.Engine.Stepped = stepped
			takes.NL_MixTone, takes.NL_MixClick, takes.NL_MixFlat, takes.NL_MixLow = nil, nil, nil, nil
			t.Check("the mix ran", ok, tostring(problem))
			-- a narrow peak: one band over both its neighbours, inside 2 to 6 kHz
			local spectrum = table.create(25, 40)
			spectrum[19] = 52 -- 3.2 kHz
			local over, at = CueMix.NarrowPeak(spectrum)
			t.Check("one band 12 dB over its neighbours at 3.2 kHz", near(over, 12) and near(at, 3200, 1), `{over} {at}`)
			spectrum[20] = 50
			t.Check("a band with a neighbour as high isn't narrow", near((CueMix.NarrowPeak(spectrum)), 2))
			spectrum[19], spectrum[20], spectrum[5] = 40, 40, 70 -- 126 Hz: outside the bands
			t.Check("a peak outside 2 to 6 kHz isn't read", near((CueMix.NarrowPeak(spectrum)), 0))
			-- two spectra alike, and apart
			local other = table.create(25, 40)
			other[20] = 70
			t.Check("a spectrum is its own like, a level apart too", near(CueMix.Similar(spectrum, spectrum), 1, 1e-9) and near(CueMix.Similar(table.create(25, 40), table.create(25, 60)), 1, 1e-9))
			t.Check("a spectrum with its weight elsewhere is under 0.97", CueMix.Similar(spectrum, other) < 0.97, tostring(CueMix.Similar(spectrum, other)))
		end,
	},
}
