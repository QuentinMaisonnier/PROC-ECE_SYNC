RAM00_inst : RAM00 PORT MAP (
		address	 => address_sig,
		byteena	 => byteena_sig,
		data	 => data_sig,
		inclock	 => inclock_sig,
		outclock	 => outclock_sig,
		rden	 => rden_sig,
		wren	 => wren_sig,
		q	 => q_sig
	);
