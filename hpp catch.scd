~hpp = ~hpp ? EM();

~hpp.catch = ~hpp.catch ? EM();

~hpp.catch.makeBuffer = { |evt|
	evt.recBuf = Buffer.alloc(s, 5 * 44100, 2 );
};

~hpp.catch.loopBuffers = [];

~hpp.catch.makeBuffer;

~hpp.catch.maxBuffers = 10;

~hpp.catch.specs = OEM();

[
	\level, 1, [0,1].asSpec,
	\catch, 0, TriggerSpec(), 
	\duration, 3, [0.5,4,\lin].asSpec
].clump(3).do({ |item|
	var key, default, spec;
	#key, default, spec = item;
	~hpp.catch[ key ] = default;
	~hpp.catch[ key.asSetter ] = { |evt, value|
		evt[ key ] = value ? default;
		evt.sn.set( key, evt[ key ] );
	};
	~hpp.catch.specs[ key ] = spec;
});

~hpp.catch[ \catch_ ] = { |evt, value, action|
	evt[ \catch ] = value;
	evt.sendTrig
};

~hpp.catch.sendTrig = { |evt, id = 1|
	evt.sn.set( \t_getPos, id );
};

~hpp.catch.copyLoop = { |evt, value = 0, action|
	var buf, duration;
	duration = evt.duration * exprand(3/4,4/3);
	buf = Buffer.alloc( s, duration * 44100, evt.recBuf.numChannels, {|buf|
		["/b_query",buf.bufnum]
	} );
	buf.doOnInfo_({
		evt.recBuf.copyLoopCF( buf, value - ((duration + 0.25) * 44100), 0.25, 
		-1, {
			evt.addBuffer( buf );
			action.value; 
			evt.changed( \newLoop ); 
			"new loop (%s) / % loops total\n".postf( duration.round(0.01), evt.loopBuffers.size );
		});
	});
};

~hpp.catch.addBuffer = { |evt, buffer|
	if( buffer.notNil ) {
		evt.loopBuffers = [ buffer ] ++ evt.loopBuffers;
	};
	while { evt.loopBuffers.size > evt.maxBuffers } {
		evt.loopBuffers.pop.free;
	};
};

~hpp.catch.clearBuffers = { |evt|
	evt.loopBuffers.do(_.free);
	evt.loopBuffers = [];
};

(
SynthDef( "hpp_catch", { |in = 0, recBuf = 0, t_getPos = 0, level = 1|
	var sig;
	sig = PrivateIn.ar( in + [0,1] ) * level.lag(0.5);
	RecordBuf.ar( sig, recBuf );
	SendTrig.kr( t_getPos, t_getPos, Phasor.ar( 0, 1, 0, BufFrames.kr(recBuf) ) );
}).load(s)
);

~hpp.catch.start = { |evt|
	evt.end;
	evt.sn = Synth( "hpp_catch", evt.getPairs([ \recBuf, \level ]), s, \addToHead ).register;
	ReceiveTrig( evt.sn, { |value, time, responder, msg|
		if( msg[2] == 1 ) { evt.copyLoop( value ); };
	});
	evt.active = true;
};

~hpp.catch.end = { |evt|
	evt.sn.free;
	evt.sn = nil;
	evt.active = false;
};



/*
~hpp.catch.start;

~hpp.catch.catch = 1;

~hpp.catch.end;

~hpp.catch.loopBuffers[0].plot;

~hpp.catch.clearBuffers;
*/