~hpp = ~hpp ? EM();

~hpp.catchPlay = ~hpp.catchPlay ? EM();

~hpp.catchPlay.ctrl = SimpleController( ~hpp.catch );

~hpp.catchPlay.ctrl.put( \newLoop, { 
	~hpp.catchPlay.startLoop;
	if( ~hpp.catchPlay.synths.size > 6 ) {
		~hpp.catchPlay.endLoop;
	};
});

~hpp.catchPlay.loadBuffers = { |evt|
	evt.shapeBuffer = Buffer.alloc(s, 512, 1, { |buf| buf.chebyMsg([0,0,1,1,0,0,0.5])});
};

~hpp.catchPlay.loadBuffers;

~hpp.catchPlay.amp = 0.5;

~hpp.catchPlay.specs = OEM();
[
	\amp, 0.5, \amp.asSpec,
	\semitones, 0, [-24,24,\lin,1,0].asSpec,
	\semiVar, 0, [0,24,\lin,1,0].asSpec,
	\distort, 0, [0,1].asSpec,
	\filter, 0.5, [0,1].asSpec,
	\lowCut, [20,5000], \freq.asRangeSpec,
	\hiCut, [1000,20000], \freq.asRangeSpec,
].clump(3).do({ |item|
	var key, default, spec;
	#key, default, spec = item;
	~hpp.catchPlay[ key ] = default;
	~hpp.catchPlay[ key.asSetter ] = { |evt, value|
		evt[ key ] = value ? default;
		evt.synths.values.do( _.set( key, evt[ key ] ) );
	};
	~hpp.catchPlay.specs[ key ] = spec;
});

~hpp.catchPlay[ \filter_ ] = { |evt, value = 0.5|
	evt[ \filter ] = value;
	evt.lowCut = [
		Env([20,20,20000],[0.5,0.5],\exp).at( value ),
		Env([20,5000,20000],[0.5,0.5],\exp).at( value )
	];
	evt.hiCut = [
		Env([20,1000,20000],[0.5,0.5],\exp).at( value ), 
		Env([20,20000,20000],[0.5,0.5],\exp).at( value )
	];
};
			
(
SynthDef( "hpp_catchPlay", { |bufnum = 0, shapeBuffer = 0, amp = 0.1, out = 2, semitones = 0, semiVar = 0, distort = 0, lowCut = #[20,5000], hiCut = #[1000,20000], gate = 1|
	var sig, env, ampx;
	var distorted;
	sig = PlayBufCF.ar( 2, bufnum, 
		Dwhite( semitones - semiVar, semitones + semiVar, inf ).round(1).midiratio,
		Dwhite( 1, 10 ),
		Dwhite( 0, BufFrames.kr(bufnum) ),
		1,
		0.1,
	);
	ampx = Amplitude.kr(sig, 0.01, 1).max(-80.dbamp);
Ê Ê 	distorted = Shaper.ar(
		shapeBuffer,
		((sig/ampx) * 0.5 * semitones.lag2(2).linlin(-24,0,2,1,\minmax) ).softclip,
		1
	) * ampx * 2;
	distorted = SoftKneeCompressor.ar( distorted, ratio: 0.25, makeUp: 0.75 );
	sig = XFade2.ar( sig, distorted, distort.linlin(0,1,-1,1) );
    
	env = Env.asr(0.5,1,0.5).kr(2,gate);
	sig = BLowCut.ar( sig, LFDNoise1.kr(0.1).exprange(	*lowCut.clip(20,20000).lag2(1) ), 3 );
	sig = BHiCut.ar( sig, LFDNoise1.kr(0.1).exprange( *hiCut.clip(20,20000).lag2(1) ), 3 );
	PrivateOut.ar( out, sig * env * amp.lag2(0.5) );
	sig = sig.collect({ |sig|
		RoundPan.ar( 4, sig, LFDNoise1.kr(0.1,2) );
	}).sum;
	Out.ar(0, sig * env * amp.lag2(0.5) * 1 );
}).load(s);
);

~hpp.catchPlay.synths = OEM();

~hpp.catchPlay.startLoop = { |evt, buf|
	buf = buf ? ~hpp.catch.loopBuffers.first;
	if( evt.synths.keys.asCollection.includes( buf ).not ) {
		evt.synths[ buf ] = Synth( "hpp_catchPlay", [ 
			\bufnum, buf, \shapeBuffer, evt.shapeBuffer 
			] ++ evt.getPairs([ \amp, \semitones, \semiVari, \distort, \lowCut, \hiCut ]) );
	};
	evt.synths[ buf ];
};

~hpp.catchPlay.endLoop = { |evt, buf = 0, action|
	if( buf.isNumber ) { buf = evt.synths.keys[ buf ] };
	if( evt.synths.keys.asCollection.includes( buf ) ) {
		evt.synths[ buf ].freeAction_( action ).release;
		evt.synths[ buf ] = nil;
	};
};

~hpp.catchPlay.endAll = { |evt|
	evt.synths.keys.copy.do({ |key|
		evt.endLoop( key );
	});
};

/*
~hpp.catchPlay.endAll;

~hpp.catchPlay.amp = 1;
~hpp.catchPlay.semitones = 0;
~hpp.catchPlay.semiVar = 0;
~hpp.catchPlay.distort = 0;
~hpp.catchPlay.filter = 0.5;

*/

// ~hpp.catch.catch = 1;