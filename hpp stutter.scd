~hpp = ~hpp ? EM();

~hpp.stutter = ~hpp.stutter ? EM();

(
SynthDef( "hpp_stutter", { |in = 0, fb = 0.9, amp = 0.1, filter = 0.5, ringAmt = 0, norm = 0, gate = 1|
	var sig, localin;
	var n = 8;
	
	sig = PrivateIn.ar( in + [0,1] ).sum;
	
	localin = LocalIn.ar( n ).rotate(3);
	localin = DelayN.ar( localin, 0.02, 0.02 ) + ( Normalizer.ar( localin, 1 ) * norm );
	
	sig = LeakDC.ar( localin * fb ) + 
		PanAz.ar(n, sig, LFDNoise3.kr(0.5,2) );
	
	//sig = sig * (Amplitude.kr(sig,0.01,0.01) > Amplitude.kr(sig, 1, 1)).lag(0.001,0.1);
	
	//sig = Resonz.ar( sig, LFNoise0.kr( {1.4 + 0.3.rand2}!n ).exprange(500, 4000).lag2(0.1), 0.1 ); 
	
	//sig = PitchShift.ar( sig, Rand(0.2.dup(n),0.2), 1.0, 0.01, 0.2 );
	
	sig = DelayC.ar( sig, 0.5, LFDNoise3.kr(0.2.dup(sig.size)).range(0.08,0.5) );
	
	sig = FreqShift.ar( sig, LFDNoise3.kr(0.1.dup(sig.size)).range(-10,10));
	
	sig = sig ring1: SinOsc.ar( LFDNoise3.kr(0.05.dup(sig.size)).range(500,3000), 0, ringAmt.clip(0,0.5) );
	sig = sig * LFPulse.ar( LFDNoise1.kr(0.2.dup(sig.size)).exprange(2,16) ).range(-40.dbamp,1).lag2(1/200);
	
	sig = BLowCut.ar( sig, 300, 3 );
	sig = BHiCut.ar( sig, filter.linexp(0,1,2000,20000), 3 );
	
	LocalOut.ar( sig );
	
	sig = XFade2.ar(
		sig,
		sig.collect({ |sig|
			var nn = 3;
			/*
			DynKlank.ar( `[ ExpRand(500.dup(4),6000), 0.1/4, Rand(0.25.dup(4),1) * 
				ringAmt.linlin(0.5,1,0.01,1,\minmax) 
			], sig );
			
			*/
			var freqs;
			freqs = ( LFNoise0.kr( Rand(0.05.dup(nn), 0.15 ) ).range( 500.cpsmidi, 6000.cpsmidi )
				+ LFDNoise3.kr(0.2.dup(4),0.2)
			).midicps;
			freqs = freqs.stutter(2);
			LPZ1.ar(
				(	
					CombC.ar( sig, 1/freqs, 1/freqs, Rand(0.25.dup(nn),1).stutter(2) * [1,0.25] * 
						ringAmt.linexp(0.5,1,0.01,2,\minmax), [0.15,-0.15 * ringAmt.linlin(0.66,1,0,1, \minmax) ]/nn
					) // ring1: SinOsc.ar( IRand( 500.cpsmidi.dup(nn), 6000.cpsmidi ), 0, 0.25 )
				).sum
			)
		}),
		ringAmt.linlin(0.5,0.75,-1,1,\minmax)
	);
	
	Out.ar( 0, SplayAz.ar(4, sig * 4 * amp) * Env.asr(0.1,1,0.1).kr(2,gate) );
	
}).load(s);
);

(
~hpp.stutter.specs = OEM();
[ 
	\in, 0, ListSpec([0,1]),
	\amp, 0.1, \amp.asSpec,
	\fb, 0.9, [0,1].asSpec,
	\filter, 0.6, [0,1].asSpec,
	\ringAmt, 0, [0,1].asSpec,
	\norm, 0, [0,1].asSpec,
].clump(3).do({ |array|
	var key, value, spec;
	#key, value, spec = array;
	~hpp.stutter[ key ] = value;
	~hpp.stutter[ key.asSetter ] = { |evt, val|
		evt[ key ] = val;
		evt.synth.set( key, val);
	};
	~hpp.stutter.specs[ key.asGetter ] = spec;
});
);

~hpp.stutter.start = { |env|
	env.end;
	env.synth = Synth( "hpp_stutter", env.getPairs( [ \in, \amp, \fb, \filter, \ringAmt, \norm] ), addAction: \addToTail );
};

~hpp.stutter.end = { |env|
	env.synth.release;
	env.synth = nil;
};

/*
~hpp.stutter.start;
~hpp.stutter.filter = 0.6;
~hpp.stutter.end;
~hpp.stutter.fb = 0.95;
~hpp.stutter.norm = -40.dbamp;
~hpp.stutter.norm = 0;
*/