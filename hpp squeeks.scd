~hpp = ~hpp ? EM();

~hpp.squeeks = ~hpp.squeeks ? EM();

~hpp.squeeks.startOSC = { |evt|
	evt.endOSC;
	evt.oscFunc = OSCFunc({ |msg, time, addr, recvPort| 
		evt.pos = msg[3];
	}, "/gyrosc/gyro", recvPort: 9999 );
};

~hpp.squeeks.endOSC = { |evt|
	evt.oscFunc.free;
	evt.oscFunc = nil;
};

~hpp.squeeks.loadBuffers = { |evt|
	"loading buffer: ".post;
	evt.buffer = Buffer.read( s,
		(thisProcess.nowExecutingPath.dirname.dirname +/+ "samples/harp_low_3.wav").postln; 
	);
};

~hpp.squeeks.loadBuffers;

~hpp.squeeks.rate = 1;
~hpp.squeeks.amp = 0.5;

~hpp.squeeks.specs = OEM();

[
	\pos, 0, [-pi,pi,\lin], true,
	\amp, 0.5, \amp.asSpec, true,
	\rate, 1, [0.25, 4,\exp].asSpec, true,
	\filter, 0, [0,1].asSpec, true,
].clump(4).do({ |item|
	var key, default, spec, setSynth;
	#key, default, spec, setSynth = item;
	~hpp.squeeks[ key ] = default;
	if( setSynth == true ) {
		~hpp.squeeks[ key.asSetter ] = { |evt, value|
			evt[ key ] = value ? default;
			evt.synths.do(_.set( key, evt[ key ] ));
		};
	};
	~hpp.squeeks.specs[ key ] = spec;
});

(
SynthDef( "hpp_squeeks", { |buffer = 0, pos = 0, rate = 2, filter = 0, amp = 0.5, gate = 1|
	var env;
	var sig, speed;
	var dspeed, sig1, sig2;
	env = Env.asr(0.5,1,0.5).kr(2,gate);
	filter = filter.lag2(0.5).clip(0,1);
	
	pos = pos.unwrap2( pi );
	speed = (Slope.kr( pos ).abs / 5).clip(0.1,1.1).lag2( LFDNoise3.kr(0.1).exprange(0.05,0.4) ) - 0.1;

	sig1 = PlayBufCF.ar(2, buffer, Dwhite(-6, 6).midiratio * rate, Dwhite(0.5, 3), Dwhite(0, BufFrames.kr(buffer) ),
		true, 0.5 
	);
	
	sig1 = BPeakEQ.ar( sig1, 2000, 5, 10 );
	//sig1 = BLowCut.ar( sig1, filter.linexp(0,1,20,1000), 2 );
	
	sig2 = PlayBufCF.ar(2, buffer, Dwhite(-6, 6).midiratio * rate * 1.5, Dwhite(0.5, 3), Dwhite(0, BufFrames.kr(buffer) ),
		true, 0.5 
	);
	
	sig2 = BLowCut.ar( sig2, filter.linexp( 0,1,1000, 1500), 2 ) * filter.linlin(0,1,1,3);
	
	sig = (sig1 * speed) + (sig2 * DelayC.kr( speed, 3, LFDNoise3.kr(0.25).exprange(0.1,2.5) ) );
	
	sig = BLowCut.ar( sig, filter.linexp(0,1,20,1000), 2 );
	
	sig = sig + (BHiCut.ar( sig1, 150, 3 ) * 0.01 * (1 - Peak.kr(speed > 0).lag(0.25,0)));
	
	sig = sig.collect({ |sig|
		RoundPan.ar( 2, sig, LFDNoise3.kr(0.25,2) ) 
	}).sum;
	
	Out.ar( 0, sig * env * amp * 30 );
	
}).load(s);
);

~hpp.squeeks.start = { |env|
	env.end;
	env.startOSC;
	env.synths = {
		Synth( "hpp_squeeks", env.getPairs( [ \buffer, \amp, \pos, \rate, \filter ] ) );
	}!6;
};

~hpp.squeeks.end = { |env|
	env.synths.do(_.release);
	env.synths = nil;
	env.endOSC;
};

/*
~hpp.squeeks.start;
~hpp.squeeks.end;
~hpp.squeeks.pos = 1;

~hpp.squeeks.startOneTask(20.rand);

(
20.do({ |i|
	~hpp.squeeks.startOneTask(i);
});
)

~hpp.squeeks.amp = 0.1;
~hpp.squeeks.amp = 0.5;
~hpp.squeeks.rate = 1;
~hpp.squeeks.rate = 2.25;
~hpp.squeeks.filter = 1;


Synth( "hpp_squeeks", [ \bufnum, ~hpp.squeeks.buffers[0], \i, 0 ] );

Synth( "hpp_squeeks", [ \bufnum, ~hpp.squeeks.buffers[8], \i, 8, \rate, 0.5 ] );

NanoKONTROL();

NanoKONTROL.sliders[0][0].action = { |sl| ~hpp.squeeks.which = sl.value };

*/

