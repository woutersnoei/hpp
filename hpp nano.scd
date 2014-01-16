~hpp = ~hpp ? EM();

~hpp.nanoScene = 1;

~hpp.startAboveZero = { |evt, which, value = 0|
	if( value > 0 ) {
		if( (~hpp[which].slLastVal ? 0) == 0 ) {
			~hpp[which].start;
		};
	} {
		if( (~hpp[which].slLastVal ? 0) > 0 ) {
			~hpp[which].end;
		};
	};
	~hpp[which].slLastVal = value;
};

(
if( NanoKONTROL.allViews.isNil ) {
	NanoKONTROL();
	NanoKONTROL.window.close;
};
if( NanoKONTROL.inPort.isArray.not ) {	
	NanoKONTROL.inPort = MIDIClient.sources.selectIndex({ |item| item.device == "nanoKONTROL" });
	x = NanoKONTROL.makeWindow;
	x.do({ |item, i|
		NanoKONTROL.allViews[i] = item;
	});
} {
	NanoKONTROL.window.front;
};
);

// limit sl1/2

NanoKONTROL.sliders[~hpp.nanoScene][0].action = { |sl| 
	~hpp.limit.amp = \amp.asSpec.map( sl.value );
	~hpp.startAboveZero( \limit, sl.value );
};
NanoKONTROL.knobs[~hpp.nanoScene][0].action = { |sl| ~hpp.limit.shift = Env([-200,0,0,200],[0.4,0.2,0.4], [-2,0,2] ).at( sl.value ) };
NanoKONTROL.sliders[~hpp.nanoScene][1].action = { |sl| ~hpp.limit.brassage =  sl.value };
NanoKONTROL.knobs[~hpp.nanoScene][1].action = { |sl| ~hpp.limit.filter =  sl.value };
NanoKONTROL.buttons[~hpp.nanoScene][0].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.limit.t_empty = 1;
	};
};
NanoKONTROL.buttons[~hpp.nanoScene][9].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.limit.frx = 1 - ~hpp.limit.frx;
	};
};

// stutter sl3

NanoKONTROL.sliders[~hpp.nanoScene][2].action = { |sl| 
	~hpp.stutter.amp = \amp.asSpec.map( sl.value );
	~hpp.startAboveZero( \stutter, sl.value );
};
NanoKONTROL.knobs[~hpp.nanoScene][2].action = { |sl| ~hpp.stutter.ringAmt = sl.value };
NanoKONTROL.buttons[~hpp.nanoScene][2].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.stutter.norm = -50.dbamp;
	};
};
NanoKONTROL.buttons[~hpp.nanoScene][2+9].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.stutter.norm = 0;
	};
};

// catchPlay sl4

NanoKONTROL.sliders[~hpp.nanoScene][3].action = { |sl| 
	~hpp.catchPlay.amp = \amp.asSpec.map( sl.value ) 
};

NanoKONTROL.knobs[~hpp.nanoScene][3].action = { |sl| 
	~hpp.catchPlay.filter = sl.value.linlin(0,1,0.1,0.9); 
	~hpp.catchPlay.distort = (sl.value.linlin(0,1,-0.7,0.7).abs - 0.2).max(0); 
};

NanoKONTROL.buttons[~hpp.nanoScene][3].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.catch.catch = 1;
	};
};
NanoKONTROL.buttons[~hpp.nanoScene][3+9].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.catchPlay.endAll;
	};
};

// squeeks sl5

NanoKONTROL.sliders[~hpp.nanoScene][4].action = { |sl| 
	~hpp.squeeks.amp = \amp.asSpec.map( sl.value );
};
NanoKONTROL.knobs[~hpp.nanoScene][4].action = { |sl| 
	~hpp.squeeks.filter = sl.value;
};
NanoKONTROL.buttons[~hpp.nanoScene][4].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.squeeks.start;
	};
};
NanoKONTROL.buttons[~hpp.nanoScene][4+9].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.squeeks.end;
	};
};

// ticks sl6

NanoKONTROL.sliders[~hpp.nanoScene][5].action = { |sl| 
	~hpp.ticks.amp = \amp.asSpec.map( sl.value );
};
NanoKONTROL.knobs[~hpp.nanoScene][5].action = { |sl| 
	~hpp.ticks.hpf = sl.value.linlin(0,1,20,1000);
	~hpp.ticks.rate = sl.value.linexp(0,1,2,3);
};
NanoKONTROL.buttons[~hpp.nanoScene][5].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.ticks.start;
	};
};
NanoKONTROL.buttons[~hpp.nanoScene][5+9].action = { |bt| 
	if( bt.value == 1 ) {
		~hpp.ticks.end;
	};
};



