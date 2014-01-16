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
	\verb,
	\nano,
].do({ |item|
	(~hpp.filepath +/+ "hpp" + item ++ ".scd").load;
});

)

/*
(
[
	\catch,
].do({ |item|
	~hpp[ item ].start;
});
)
*/