~hpp = ~hpp ? EM();

~hpp.limit = ~hpp.limit ? EM();

(
SynthDef( "hpp_limit", { |in = 0, gain = 10, limit = -10, amp = 0.1, gate = 1, amt = 0.5, t_empty = 0, frx = 0, smear = 0, convbuf = 0, noiseMix = -1, noiseDens = 1000, brassage = 0, filter = 0.5, auxmix = 0, echomix = 0, shift = 0|
	var sig, sigin, env, limited;
	var fft, copy, noise, ampx;
	var aux;
	sigin = PrivateIn.ar(in + [0,1]).sum;
	aux = PrivateIn.ar(2 + [0,1]).sum;
	//sig = PartConv.ar( sig, 2048, convbuf );
	sig = BHiShelf.ar( sigin, 2500, 1, Amplitude.kr( sigin, 0.125, 0.5 ).ampdb.linlin(-50 + gain, -30 + gain, -20,0,\minmax) );
	sig = sig * (Amplitude.ar( sigin, 0.0001, 0.2 ) > -80.dbamp).lag2(0.1,1);
	sig = sig * gain.dbamp;
	filter = filter.varlag(0.125);
	sig = BLowCut.ar( sig, filter.linexp(0.5,1,20,20000,\minmax), 2 );
	sig = BHiCut.ar( sig, filter.linexp(0,0.5,20,20000,\minmax), 2 );
	sig = FreqShift.ar( sig, shift );
	limited = Limiter.ar( sig, limit.dbamp, 0.01 ) + WhiteNoise.ar(0.00000001);
	/*
	ampx = Amplitude.kr(sig, 0.01, 1).max(-80.dbamp);
Ê Ê 	limited = LeakDC.ar(
		Shaper.ar(
			b,
			((limited/ampx) * 0.5).softclip,
			2
		) * ampx;
	);
	*/
	fft = FFT( LocalBuf( 4096 ), limited, hop: 0.25 );
	copy = PV_Copy( fft, LocalBuf( 4096 ));
	noise = FFT( LocalBuf( 4096 ), 
		//Trig.ar( Dust.ar( 10 ), 0.1 ) * WhiteNoise.ar(0.033),
		//GrainSin.ar( 1, Dust.ar(noiseDens), 1/noiseDens, WhiteNoise.ar.exprange(40,10000) ) 
		//* 0.033 * 0.5, 
		/*
		Normalizer.ar(
		15.collect({
			0.5 * Formant.ar( 
				SinOsc.kr(0.1 rrand: 0.2, 0.0 rrand: 2pi).exprange(1,20) * noiseDens.linlin(10,1000,1/6, 1000), 
				SinOsc.kr(0.1 rrand: 0.2, 0.0 rrand: 2pi).exprange(500,10000), 
				SinOsc.kr(0.1 rrand: 0.2, 0.0 rrand: 2pi).exprange(500,10000)
			)
		}).sum / 15,
		0.05
		)
		*/
		(Dust2.ar(noiseDens) * 0.25).blend( Normalizer.ar( aux, 0.01 ), auxmix ),
		hop: 0.25 
	); 
	noise = PV_Whiten( noise, LocalBuf(4096).clear, 1, 0.5 );
	//fft = PV_MaxMagN( fft, 70 );
	//fft = PV_MagSmooth( fft, (Amplitude.kr( sig ) > (-70 + gain).dbamp).linlin(0,1,0.99999,0) );
	//fft = PV_MinMagN( fft, 2020 );
	fft = PV_MagSmooth( fft, 0.99 );
	fft = PV_MagSubtract( copy, fft, 1 );
	//fft = PV_MagSmooth( fft, (Amplitude.kr( sig ) > (-70 + gain).dbamp).linlin(0,1,0.99999,0) );
	fft = PV_MagSmooth( fft, amt.linlin(0,1,1,5).tanh * (1-Trig.kr( t_empty, 4096/SampleRate.ir ) ));
	fft = PV_MagFreeze( fft, frx );
	//fft = PV_MagSmear( fft, smear );
	fft = PV_MinMagN( fft, 2046 - smear );
	noise = PV_MagMul( noise, fft );
	sig = XFade2.ar( IFFT( fft ), IFFT( noise ), noiseMix );
	//sig = limited;
	//sig = sig + sigin;
	sig = SplayAz.ar(4, ({ |i|
		var sg;
		sg = BBandStop.ar( sig, LFDNoise3.kr(0.5).exprange(500,5000), 0.1 );
		sg = BBandStop.ar( sg, LFDNoise3.kr(0.5).exprange(500,5000), 0.1 );
		PitchShift.ar( sg, {0.1 rrand: 0.2}!4, 0.99 * ([0,12,12,0] + ({0.04.rand}!4)).midiratio, 0.01, 0.2, 			[1,0.25,1,0.25] 
		) * (
			//LFDNoise0.kr({10.9 rrand: 20}!4).range(0,1) <= (1-brassage)
			SinOsc.kr( LFDNoise1.kr( {0.5 rrand: 1.5}!4 ).range( brassage * 2, brassage * 20 ) ).linlin(-1,1,1-(brassage*5),1+(brassage*0.5)).clip(0,1)
			).lag(0.001)
	}!4).flat
	);
	
	//sig.size.postln;
	/*
	sig = Splay.ar( [-6,-3,0,3,6].collect({ |item|
		PitchShift.ar( sig, {0.1 rrand: 0.2}!2, item.midiratio, 0.01, 0.2 ) * LFDNoise3.kr( 20 ).max(0) 
	}).flat );
	*/
	//sig = sig * amt
	//sig = sig * Splay.ar( LFDNoise3.ar(15.dup(4)).max(0) );
	sig = sig * Env([0,0,1],[0.5,0.1]).kr;
	
	/*
	sig = XFade2.ar( sig, (
		DelayC.ar( limited / (limit.dbamp), 4, LFDNoise3.kr(0.1.dup(4) ).range(0.5,4) ) ring1: 
		SinOsc.ar( LFDNoise3.kr(0.1.dup(4) ).exprange(1000,4000), 0, 0.25 ) 
		).collect({ |item|
			RoundPan.ar( 4, item, LFDNoise3.kr(0.1) * 2 );
		}).sum * Amplitude.kr( sig, 1, 1 ).lag2(1),
		echomix.linlin(0,1,-1,1).lag2(0.5)
	);
	*/
	
	// + PitchShift.ar( sig, 0.25.dup, 0.99 * 0.5, 0.01, 0.25  );
	env = Env.asr(0.1, 1, 0.1).kr( 2, gate );
	Out.ar( 0, sig * env * 3 * amp.lag2(1) );
}).load(s);
);

(
~hpp.limit.specs = OEM();
[ 
	\in, 0, ListSpec([0,1]),
	\gain, 40, [0,36,\lin,1,10].asSpec,
	\filter, 0.5, [0,1].asSpec,
	\limit, -10, [-36,0,\lin,1,-10].asSpec,
	\brassage, 0, [0,1].asSpec,
	\amp, 0.1, \amp.asSpec,
	\amt, 0.5, [0,1,\lin,0,0.5].asSpec,
	\smear, 0, [0, 200,\lin,1,0].asSpec,
	\noiseMix, -1, [-1,1,\lin].asSpec,
	\noiseDens, 1000, [10,1000,\lin].asSpec,
	\auxmix, 0, [0,1].asSpec,
	\echomix, 0, [0,1].asSpec,
	\frx, 0, BoolSpec(false),
	\t_empty, 1, TriggerSpec(),
	\shift, 0, [-200,200].asSpec,
].clump(3).do({ |array|
	var key, value, spec;
	#key, value, spec = array;
	~hpp.limit[ key ] = value;
	~hpp.limit[ key.asSetter ] = { |evt, val|
		evt[ key ] = val;
		evt.synth.set( key, val);
	};
	~hpp.limit.specs[ key.asGetter ] = spec;
});
);

~hpp.limit.start = { |env|
	env.end;
	env.synth = Synth( "hpp_limit", env.getPairs( [ \in, \gain, \limit, \filter, \amp, \amt, \noiseMix, \noiseDens, \smear, \frx, \brassage, \auxmix, \echomix, \shift ] ), addAction: \addToTail );
};

~hpp.limit.end = { |env|
	env.synth.release;
	env.synth = nil;
};

/*
~hpp.limit.start;
~hpp.limit.end;


~hpp.limit.auxmix = 1;
~hpp.limit.auxmix = 0;
~hpp.limit.auxmix = 0.2;
~hpp.limit.gain = 50;
~hpp.limit.limit = -10;
~hpp.limit.amp = 0.0;
~hpp.limit.amt = 0.1;
~hpp.limit.amt = 0.5;
~hpp.limit.t_empty = 0.75;
~hpp.limit.frx = 1;
~hpp.limit.frx = 0;
~hpp.limit.filter = 0.5;
~hpp.limit.filter = 0.5;
~hpp.limit.noiseMix = -1;
~hpp.limit.noiseMix = 1;
~hpp.limit.noiseDens = 1000;
~hpp.limit.echomix = 1;
~hpp.limit.echomix = 0.5;
~hpp.limit.echomix = 0;
~hpp.limit.shift = 20;
~hpp.limit.shift = 0;

*/