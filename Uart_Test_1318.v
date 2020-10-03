module Uart_Test_1318 ();
 
  // Testbench использует тактовую частоту 10 МГц
  // Want to interface to 115200 baud UART
  // 10_000_000 / 115200 = 87 Clocks Per Bit.
  parameter BAUD_RATE = 115200;             //частота приема
  parameter CLK_FREQ  = 50_000_000          //reference frequency
  
  local parameter  Length_Period_Ref_Freq  = (1/CLK_FREQ *10^9) ; // 20ns length of period of reference frequency (10МГц) in ns
  local parameter  Length_Period_Rev_Bit   = Length_Period_Ref_Freq* (CLK_FREQ/BAUD_RATE) ; //8700tact длина принимаемого бита на частоте приемника в наносекундах
  local parameter  Namber_Tact_Rec_Bit     = CLK_FREQ/BAUD_RATE;   //434tact счет 87 такирует схему приема т.к. это длина принимаемого бита в тактах приемника
   
  reg Clock_TX = 0;
  reg Clock_RX = 0;
  reg  start  = 0;                        //линия сигнала на  записи байта в передатчик (внешний старт передатчика)
  wire new_rx_data  ;                     //флаг состояния готовности к работе - переходит в "1"
  reg [7:0] r_Tx_Byte = 0;
  reg r_Rx_Serial = 1;
  wire [7:0] w_Rx_Byte;
  
  // подключение тестового модуля к приемнику и передатчику
  uart_rx #(.CLKS_PER_BIT(Namber_Tact_Rec_Bit))              UART_RX_INST
    (.i_Clock(Clock_TX),
     .i_Rx_Serial(r_Rx_Serial),
     .o_Rx_DV(),
     .o_Rx_Byte(w_Rx_Byte)
     );
   
  uart_tx #(.CLKS_PER_BIT(Namber_Tact_Rec_Bit))              UART_TX_INST
    (.i_Clock(Clock_TX),
     .i_Tx_DV( start),
     .i_Tx_Byte(r_Tx_Byte),            // восьмибитный вход на приемник
     .o_Tx_Active(),                   // флаг окончания передачи            - переходит в "0"     ///ЗА ТАКТ до окончания работы автомата выставляется флаг     "r_Tx_Active"  ///
     .o_Tx_Serial(),                   //последовательный выход на передатчик
     .o_Tx_Done(new_rx_data  )             //флаг состояния готовности к работе - переходит в "1"
     );
   
 /*********************************************************************************************************************/ 
     forever #10  Clock_TX = !Clock_TX;  //  частота передатчика с периодом 10 временных единиц
	 forever #20  Clock_RX = !Clock_RX;  //частот приемника
 /*********************************************************************************************************************/
  // описание сценария приема пакета 
  task UART_WRITE_BYTE;
    input [7:0] i_Data;              //линия подачи пакетов для тестирования
    integer     i;                  //номера пакетов
    begin
       
      // отправка стартового бита
      r_Rx_Serial <= 1'b0;
      #(Length_Period_Rev_Bit);  //  выждать время равное длинее одного принимаемого /отправляемого бита
      
       // отправка байта данных
      for (i=0; i<8; i=i+1)        // выход из цикла по отправке восьми бит с соответствующими временными задержками междуними
        begin
          r_Rx_Serial <= i_Data[i];
          #(Length_Period_Rev_Bit);      	// после каждой интерации цикла выждать время отправки одного бита
        end
       
      // отправка стоп бита
      r_Rx_Serial <= 1'b1;
      #(Length_Period_Rev_Bit);
     end
  endtask // UART_WRITE_BYTE
 /******************************************************************************************************************/  
 // Разбираюсь
  initial
    begin
       
      // Отправим пакет на линию в идеальных условиях (разрешение на передачу строго один период тактовой)
      
      @(posedge Clock_TX);      //ждем события "фронт тактовой"
       start <= 1'b1;         //даем разрешение на передачу
      r_Tx_Byte <= 8'7d;      // пакет на вход приемника
      @(posedge Clock_TX);      //ждем события "фронт тактовой"
       start <= 1'b0;         
      @(posedge new_rx_data  );    //ждем события о заверщении работы автомата передачи
    /****************************************************************************************************************/
	//далее сценарий для записи принимаемого пакета
      @(posedge Clock_TX);     			  //*на следующем фронте после завершения передачи      //
										  //применим сценарий для записи принимаемого байта(пакета)
										  //т.е. на соответвие протоколу( наличие стоп бита,старт бита и т.п.)
		UART_WRITE_BYTE(8'h7d);  // применяя сценарий записи приема пакета
      @(posedge Clock_TX);
             
      //сравниваем принятый байт с отправленным 
      if (w_Rx_Byte == 8'h7d)           
        $display("Test Passed - Correct Byte Received");
      else
        $display("Test Failed - Incorrect Byte Received");
       
    end
  
endmodule