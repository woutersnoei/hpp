(
// live electronics
// Trio, W. Snoei
// for electronic harp and live electronics

~hpp = ~hpp ? EM();

~hpp.filepath = thisProcess.nowExecutingPath.dirname;

[
	\ir,
	\limit,
	\stutter, 
	\catch,
	\catchPlay,
	\squeeks,
	\ticks,
	\delays,
	// \verb,
	\nano,
].do({ |item|
	(~hpp.filepath +/+ "hpp" + item ++ ".scd").load;
});

~hpp.startAll = { |evt|
	[	
		\ir,
		\catch,
	].do({ |item|
		~hpp[ item ].start;
	});
	NanoKONTROL.setScene(1);
};

~hpp.endAll = { |evt|
	[
		\limit,
		\stutter, 
		\catch,
		\catchPlay,
		\squeeks,
		\ticks,
		\delays,
	].do({ |item|
		~hpp[ item ].end;
	});
	evt.ir.stop;
};

)

/*

~hpp.ir.end
(
[
	\catch,
].do({ |item|
	~hpp[ item ].start;
});
)
*/