with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;

pragma Warnings (Off);
with System.BB.Time;
use System.BB.Time;
with System.Task_Primitives.Operations;
pragma Warnings (On);
with CPU_Budget_Monitor;

package body Periodic_Tasks is

   package STPO renames System.Task_Primitives.Operations;

   task body Periodic_First_CPU is
      Next_Period : Ada.Real_Time.Time;
      Period_To_Add : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds (Period);
   begin
      STPO.Set_Budget (STPO.Self, System.BB.Time.Microseconds (Budget));
      Next_Period := Ada.Real_Time.Clock + Period_To_Add;

      if System.BB.Time.Microseconds (Budget) = STPO.Get_Thread_Id (STPO.Self).Budget then
         Ada.Text_IO.Put_Line ("Budget correctly setted");
      end if;

      Initialization_Done.Inform_Monitor (System.BB.Time.Microseconds (Budget));

      loop
         delay until Next_Period;
         Next_Period := Next_Period + Period_To_Add;
      end loop;

   end Periodic_First_CPU;

   procedure Init is
   begin
      loop
         Ada.Text_IO.Put_Line ("Init");
      end loop;
   end Init;
   
   protected body Initialization_Done is
      procedure Inform_Monitor (Budget : System.BB.Time.Time_Span)is
      begin
         CPU_Budget_Monitor.Start_Monitor (Budget);
      end Inform_Monitor;
   end Initialization_Done;

   ------------------------
   --  Tasks Allocation  --
   ------------------------

   P1 : Periodic_First_CPU (Pri => 10, Budget => 300_000, Period => 1_000_000);
   
end Periodic_Tasks;