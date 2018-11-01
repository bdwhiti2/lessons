//Select node proxies used in the Embry Riddle Chaosflöte performance
//Benjamin D. Whiting (2018-11-01)

//NOTE: MAKE SURE YOU MONITOR USING HEADPHONES OR EARBUDS TO PREVENT FEEDBACK, ESPECIALLY IF USING
//A LAPTOP'S INTERNAL MIC/SPEAKERS!!!!

//STEP 1
(
Server.default = s = Server.local;
s.options
.memSize_(2 << 19)
.sampleRate_(48000)
.hardwareBufferSize_(512);

b = Buffer.alloc(s, 666 * s.sampleRate); //for ~freeze
)

//STEP 2
p = ProxySpace.push(s.boot);

//HAVE FUN!
(
~binScrambler = { |amp=1|
	var sig = SoundIn.ar;
	var chain = FFT(LocalBuf(2048), sig);

	chain = PV_BinScramble(chain, XLine.kr(0.1, 0.5, 10), XLine.kr(0.1, 0.5, 10));

	IFFT(chain) * amp;
};
)

(
~freeze = { |panRate=10, t_trig=0|
	var sig = SoundIn.ar;
	var rand = Rand(30, 60);
	var writePos = Phasor.ar(0, 1, 0, BufFrames.kr(b[3]));
	var readPos = writePos * ~freezeLine1;
	var shift = PitchShift.ar(sig, pitchRatio: LFNoise1.kr(LFNoise0.kr(0.33), 0.5, 0.5).abs, mul: 1.5);
	var trig = Trig.kr(t_trig, LFNoise0.kr(0.1, 3).abs);
	var chain1, chain2;
	var ifft1, ifft2, resynth;

	sig = sig + (sig * [0, 0, 1].choose);
	chain1 = FFT(LocalBuf(2048), sig);
	chain1 = PV_MagFreeze(chain1, trig);
	ifft1 = IFFT(chain1);

	BufWr.ar(ifft1, b[3], writePos);

	ifft2 = BufRd.ar(1, b[3], readPos);
	chain2 = FFT(LocalBuf(2048), ifft2);
	chain2 = PV_MagFreeze(chain2, trig);
	ifft2 = IFFT(chain2) * Line.kr(1, 1.5, rand);

	ifft1 = Pan2.ar(ifft1, LFNoise1.kr(panRate.reciprocal));
	ifft2 = Pan2.ar(ifft2, LFNoise1.kr(panRate));
	resynth = ifft1 + ifft2;

	resynth;
};

~freezeLine1 = { DC.kr(0.25) };
)

(
~chopper = { |freq=60, amp=1.5|
	var sig = SoundIn.ar;
	var chain;

	chain = FFT(LocalBuf(1024), sig);
	chain = PV_PhaseShift(chain, SinOsc.kr(freq, pi, amp));
	chain = IFFT(chain);

	chain;
};
)

(
~distortion = { |hpf_freq=400, lpf_freq=3800, eq_freq=120, rq=0.7, db=8,	hpf_amp=5, lpf_amp=0.5, smoothing=1, amp=0.2, amt=0.9|
	var hpf, lpf, eq;
	var chain, chainsmooth, smooth;
	var clean;
	var sig_in = SoundIn.ar;
	var coefficient = 2 * amt / (1 - amt);

	hpf = HPF.ar(sig_in, hpf_freq, hpf_amp);
	lpf = LPF.ar((1 + coefficient) * hpf / (1 + (coefficient * hpf.abs)), [lpf_freq, (lpf_freq+100)], lpf_amp);
	eq = MidEQ.ar(lpf, eq_freq, rq, db);

	chain = FFT(LocalBuf(2048), eq);
	chainsmooth = PV_MagSmooth(chain, smoothing);
	chain = PV_MagSubtract(chain, chainsmooth, 1);
	smooth = IFFT(chain);

	clean = Pan2.ar(HPF.ar(smooth, 220));

	clean * amp;
};
)

(
~creepyReverb = { |pan=0, preAmp=1.5, amp=0, initDelayTime=0.5, maxDelayTime=5, min=0.1, max=1|
	var sig = SoundIn.ar;
	var transform = BPF.ar(sig, 2000, 1/12);
	var delay;

	transform = BPF.ar(transform * 0.5, 400, 1/3) + (transform.clip(0.4) * 0.15);
	transform = HPF.ar(HPF.ar(transform, 90), 90) * 100;

	delay = Mix.fill(10, { |i|
		var delayTime = (initDelayTime + i + Rand(min, max)) / 2;
		var delayed = DelayN.ar(transform, maxDelayTime, delayTime, 0.33 ** i);

		Pan2.ar(delayed, LFNoise1.kr(1));
	});

	Splay.ar(Mix([transform.dup, delay]) * amp, center: pan)
};
)

~crossover = { |amp=0.5, smooth=0.99| CrossoverDistortion.ar(SoundIn.ar, smooth: smooth) * amp };