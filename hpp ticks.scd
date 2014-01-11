~hpp = ~hpp ? EM();

~hpp.ticks = ~hpp.ticks ? EM();

~hpp.ticks.start = { |evt|
	evt.end;
	evt.which = nil;
	evt.oscFunc = OSCFunc({ |msg, time, addr, recvPort| 
		evt.which = msg[2].linlin(-0.09pi,-0.005pi,1,0, \minmax);
	}, "/gyrosc/gyro", recvPort: 9999 );
};

~hpp.ticks.end = { |evt|
	evt.oscFunc.free;
	evt.oscFunc = nil;
};

~hpp.ticks.loadBuffers = { |evt|
	evt.buffers =  Buffer.readDir( 
		thisProcess.nowExecutingPath.dirname.dirname +/+ 
		"samples/harp-ticks", 
		nil, 
		"wav" 
	);
};

~hpp.ticks.loadBuffers;

~hpp.ticks.specs = OEM();

[
	\amp, 0.5, \amp.asSpec, true,
	\rate, 2, [0.25, 4,\exp].asSpec, false,
	\hpf, 20, \freq.asSpec, false,
].clump(4).do({ |item|
	var key, default, spec, setSynth;
	#key, default, spec, setSynth = item;
	~hpp.ticks[ key ] = default;
	if( setSynth == true ) {
		~hpp.ticks[ key.asSetter ] = { |evt, value|
			evt[ key ] = value ? default;
			evt.synths.do(_.set( key, evt[ key ] ));
		};
	};
	~hpp.ticks.specs[ key ] = spec;
});

~hpp.ticks[ \rate_ ] = nil;

~hpp.ticks.which_ = { |evt, which|
	var old, size, arr, rate;
	if( which.isNil ) {
		evt[ \which ] = 0;
		evt[ \lastWhich ] = nil;
	} {
		size = evt.buffers.size - 1;
		old = evt[ \which ];
		evt[ \which ] = which;
		rate = 1;
		if( old > which ) {
			old = old - (1/size);
			which = which - (1/size);
			rate = 0.5;
		};
		arr = ((old * size).floor .. (which * size).floor);
		arr.pop;
		arr.do({ |item| evt.startOneTask( item, rate ) });

	};
};

~hpp.ticks.which = nil;

/*
~hpp.ticks.which = 0.49; "";
~hpp.ticks.which = 0; "";
~hpp.ticks.which = 1; "";
~hpp.ticks.which = 0.9; "";
*/

~hpp.ticks.startOneTask = { |evt, which = 0, rate = 1|
	if( evt.task.isPlaying ) {
		evt.waitLine = evt.waitLine.add( [ which, rate ] );
	} {
		evt.waitLine = [ [ which, rate ] ];
		evt.task = Task({
			var wh, rt;
			while { evt.waitLine.size > 0 } {
				#wh, rt = evt.waitLine[0];
				evt.waitLine = evt.waitLine[1..];
				if( wh.notNil ) {
					evt.startOne( wh, rt );
				};
				(0.02 rrand: 0.05).wait;
			};
		}).start;
	};
};

~hpp.ticks.startOne = { |evt, which = 0, rate = 1|
	var buf, index;
	if( evt.lastWhich != which ) {
		evt.synths = evt.synths.add( 
			Synth( "hpp_ticks", [ 
				\bufnum, evt.buffers[ which ], 
				\i, which,
				\amp, evt.amp ? 0.5,
				\rateScale, rate * which.linexp(0,20,0.9,1/0.9),
				\rate, evt.rate ? 2,
				\hpf, evt.hpf ? 20,
			] ).freeAction_({ |synth|
				evt.synths.remove( synth );
			});
		);
		if( evt.synths.size > 8 ) { evt.synths.remove( evt.synths.first.release ); };
		evt.lastWhich = which;
	};
};

(
SynthDef( "hpp_ticks", { |bufnum = 0, i = 0, rate = 2, rateScale = 1, hpf = 20, amp = 0.5, gate = 1|
	var env;
	var sig, verb;
	var dur;
	dur =  (BufFrames.kr( bufnum ) / SampleRate.ir) / rate;
	hpf = hpf.clip(20,20000);
	
	env = Env([1,1,3,0], [0.125, 0.25, dur - 0.375], [0,0,-6] );
	env = env.kr(2);
	sig = PlayBuf.ar(2, bufnum, rate * rateScale );
	sig = Pan2.ar( sig[0], i.linlin(0,20,-1,1) ) + Pan2.ar( sig[1], i.linlin(0,20,1,-1) );
	verb = FreeVerb.ar( sig * Env([0,0,1],[0.075,0.1]).kr, 1, 1, 0.5);
	sig = (sig * hpf.explin(200,1000,1,0.5,\minmax) )+ (verb * Env([0,0,1],[0.125,3]).kr);
	sig = sig ring1: SinOsc.ar( hpf * ExpRand(1.dup,3) * rate * rateScale, 0, hpf.explin(20,200,0,1,\minmax) );
	sig = (sig * Line.ar(hpf.explin(20,200,1,0,\minmax),0,0.1)) + PitchShift.ar( sig, 0.1, 1, hpf.explin(20,200,0,0.01,\minmax), hpf.explin(20,200,0,0.01,\minmax) );
	sig = BLowCut.ar( sig, hpf.lag2(1).clip(20,20000), 3 ) * hpf.explin(20,200,1,0.75,\minmax);
	Out.ar( 0, sig * env * Env.cutoff(0.1).kr(2,gate) * amp);
}).load(s);
);

/*

~hpp.ticks.start;

~hpp.ticks.end;

~hpp.ticks.startOneTask(20.rand);

(
20.do({ |i|
	~hpp.ticks.startOneTask(i);
});
)

~hpp.ticks.amp = 0.1;
~hpp.ticks.amp = 0.5;
~hpp.ticks.rate = 5;
~hpp.ticks.rate = 2.25;
~hpp.ticks.rate = 2;
~hpp.ticks.rate = 1;

~hpp.ticks.hpf = 800;
~hpp.ticks.hpf = 20;


Synth( "hpp_ticks", [ \bufnum, ~hpp.ticks.buffers[0], \i, 0 ] );

Synth( "hpp_ticks", [ \bufnum, ~hpp.ticks.buffers[8], \i, 8, \rate, 0.5 ] );

NanoKONTROL();

NanoKONTROL.sliders[0][0].action = { |sl| ~hpp.ticks.which = sl.value };

*/

