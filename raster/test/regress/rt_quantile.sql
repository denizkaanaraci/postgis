SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	)
	, 1, TRUE, ARRAY[0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]::double precision[]
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	)
	, 1, ARRAY[0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1]::double precision[]
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	),
	1, TRUE
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	),
	1
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	),
	ARRAY[0.05, 0.95]::double precision[]
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	)
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	),
	1, TRUE, 0.05
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	),
	1, 0.95
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	),
	TRUE, 0.7
);
SELECT * FROM ST_Quantile(
	ST_SetValue(
		ST_SetValue(
			ST_SetValue(
				ST_AddBand(
					ST_MakeEmptyRaster(10, 10, 10, 10, 2, 2, 0, 0,-1)
					, 1, '64BF', 0, 0
				)
				, 1, 1, 1, -10
			)
			, 1, 5, 4, 0
		)
		, 1, 5, 5, 3.14159
	),
	0.45
);
