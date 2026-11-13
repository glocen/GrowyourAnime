--!strict
-- Audio cases (pure): the level check's measure (ServerStorage.NL_Tools.Audio.Loudness; docs/asset-requests.md, AR8 A)
-- reads what ITU-R BS.1770-4 says it should, on signals whose answers are known.
-- Runs in Studio (LogicTests) and with Studio closed (tools/checks/logic_offline.luau).

local Loudness = require(game:GetService("ServerStorage").NL_Tools.Audio.Loudness)

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
}
