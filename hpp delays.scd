~hpp = ~hpp ? EM();

~hpp.delays = ~hpp.delays ? EM();

(
SynthDef( "hpp_delays", { |direct = 0, gate = 1, amp = 0.1|
	var sig;
	sig = In.ar(0,4) + ( PrivateIn.ar([0,1]) * direct );
	sig = BLowCut.ar(sig,200,1);
	sig = DelayC.ar( sig, 2, LFDNoise3.kr(0.075.dup(4)).range(0,2) );
	sig = sig.collect({ |sig|
		sig = PitchShift.ar(sig, 0.2, 1, 0.01, 0.2 );
		RoundPan.ar(4, sig, LFDNoise3.kr(0.1) * 2 );
	});
	Out.ar( 0, sig * amp * Env.asr(0.1,1,0.1).kr(2,gate) );
}).load(s);
);

(
~hpp.delays.specs = OEM();
[ 
	\amp, 0.5, \amp.asSpec,
	\direct, 0, \amp.asSpec
].clump(3).do({ |array|
	var key, value, spec;
	#key, value, spec = array;
	~hpp.delays[ key ] = value;
	~hpp.delays[ key.asSetter ] = { |evt, val|
		evt[ key ] = val;
		evt.synth.set( key, val);
	};
	~hpp.delays.specs[ key.asGetter ] = spec;
});
);

~hpp.delays.start = { |env|
	env.end;
	env.synth = Synth( "hpp_delays", env.getPairs( [ \amp, \direct ] ), addAction: \addToTail );
};

~hpp.delays.end = { |env|
	env.synth.release;
	env.synth = nil;
};

/*
~hpp.delays.start;
~hpp.delays.end;
~hpp.delays.amp = 0.25;

*/