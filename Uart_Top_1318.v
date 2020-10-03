
	// Топовый модуль, для соединения передатчика и приёмника
	module Uart_Top_1318
	(
		input Clk_TX ,                                   //опорная  
		input Clk_RX ,
		input Reset_T,                                   // сброс,активен по "0" 
		input Start,                                     // линия сигнала на  записи байта в передатчик (внешний старт передатчика)
		input [7:0] Data_TX_In,                          // восьмибитный вход на приемник
		output reg  Ok_Data_Rx                           // сигнал готовности для считывания принятого байта с регистра
		output reg  [7:0] DATA_RX_Out                    
	);


		wire TX_Out;

	// подключение модуля передатчика
		Uart_TX_1318(Clk_TX, Data_TX_In, Start, Reset_T, TX_Out);
	// подключение модуля приёмника
		Uart_RX_1318(Clk_RX, Reset_R, DATA_RX_In , Ok_Data_Rx, DATA_RX_Out );

	endmodule

