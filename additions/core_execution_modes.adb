package body Core_Execution_Modes is

   procedure Set_Core_Mode (Core_Mode : Mode; CPU_Id : CPU) is
      pragma Unreferenced (CPU_Id);
   begin
      --  Interrupts must be disabled
      Mode_Core_1 := Core_Mode;
   end Set_Core_Mode;

   function Get_Core_Mode (CPU_Id : CPU) return Mode is
      pragma Unreferenced (CPU_Id);
   begin
      --  Interrupts must be disabled
      return Mode_Core_1;
   end Get_Core_Mode;

end Core_Execution_Modes;