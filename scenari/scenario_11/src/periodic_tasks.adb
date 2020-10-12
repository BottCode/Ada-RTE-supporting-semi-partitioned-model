with Ada.Real_Time; use Ada.Real_Time;
with Ada.Text_IO;

pragma Warnings (Off);
with System;
with System.BB.Time;
use System.BB.Time;
with System.Task_Primitives.Operations;
with System.BB.Threads.Queues;
pragma Warnings (On);

with Production_Workload;
with Experiments_Data;

package body Periodic_Tasks is

   package STPO renames System.Task_Primitives.Operations;

   ---------------------
   --  type Low_Crit  --
   ---------------------

   task body Low_Crit is
      Next_Period : Ada.Real_Time.Time := Ada.Real_Time.Time_First + Ada.Real_Time.Microseconds (Experiments_Data.Delay_Time);
      Period_To_Add : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds (Period);
   begin
      STPO.Initialize_LO_Crit_Task (STPO.Self, System.BB.Time.Microseconds (Low_Critical_Budget), Period, Is_Migrable);

      loop
         delay until Next_Period;
         Production_Workload.Small_Whetstone (Workload);
         Next_Period := Next_Period + Period_To_Add;
      end loop;
   end Low_Crit;

   ----------------------
   --  type High_Crit  --
   ----------------------

   task body High_Crit is
      Next_Period : Ada.Real_Time.Time := Ada.Real_Time.Time_First + Ada.Real_Time.Microseconds (Experiments_Data.Delay_Time);
      Period_To_Add : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds (Period);
   begin
      STPO.Initialize_HI_Crit_Task (STPO.Self, System.BB.Time.Microseconds (Low_Critical_Budget), System.BB.Time.Microseconds (High_Critical_Budget), Period);

      loop
         delay until Next_Period;
         --  Ada.Text_IO.Put_Line (Integer'Image (Pri) & " = " & Integer'Image (System.BB.Threads.Queues.Running_Thread.Base_Priority));
         System.BB.Threads.Queues.Print_Queues;
         Production_Workload.Small_Whetstone (Workload);
         Next_Period := Next_Period + Period_To_Add;
      end loop;
   end High_Crit;

   ------------
   --  Init  --
   ------------

   procedure Init is
      Next_Period : Ada.Real_Time.Time := Ada.Real_Time.Time_First + Ada.Real_Time.Microseconds (Experiments_Data.Delay_Time);
      Period_To_Add : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds (10_000_000);
   begin
      delay until Next_Period + Period_To_Add;
      Ada.Text_IO.Put_Line ("----------------------");
      Ada.Text_IO.Put_Line ("--  END EXPERIMENT  --");
      Ada.Text_IO.Put_Line ("----------------------");
      System.BB.Threads.Queues.Print_BE_Log;
      loop
         null;
      end loop;
   end Init;

   ---------------------------------------------
   --  Tasks allocation => start experiments  --
   ---------------------------------------------

   -------------
   --  CPU 1  --
   -------------

   HC_1_1 : High_Crit (Pri => 40, Low_Critical_Budget => 100_000, High_Critical_Budget => 500_000, Workload => 30_000, Period => 1_050_000, CPU_Id => CPU'First);
   
   HC_1_2 : High_Crit (Pri => 45, Low_Critical_Budget => 100_000, High_Critical_Budget => 1_000_000, Workload => 30_000, Period => 1_550_000, CPU_Id => CPU'First);

   LC_1_1 : Low_Crit (Pri => 20, Low_Critical_Budget => 300_000, Is_Migrable => True, Workload => 1, Period => 22_000_000, CPU_Id => CPU'First);

   LC_1_2 : Low_Crit (Pri => 25, Low_Critical_Budget => 140_000, Is_Migrable => False, Workload => 1, Period => 160_000, CPU_Id => CPU'First);

   -------------
   --  CPU 2  --
   -------------

   HC_2_1 : High_Crit (Pri => 30, Low_Critical_Budget => 100_000, High_Critical_Budget => 600_000, Workload => 30_000, Period => 1_000_000, CPU_Id => CPU'Last);
   
   HC_2_2 : High_Crit (Pri => 35, Low_Critical_Budget => 100_000, High_Critical_Budget => 1_000_000, Workload => 30_000, Period => 1_550_000, CPU_Id => CPU'Last);

   LC_2_1 : Low_Crit (Pri => 10, Low_Critical_Budget => 300_000, Is_Migrable => True, Workload => 1, Period => 22_000_000, CPU_Id => CPU'Last);

   LC_2_2 : Low_Crit (Pri => 15, Low_Critical_Budget => 140_000, Is_Migrable => False, Workload => 1, Period => 160_000, CPU_Id => CPU'Last);

   task End_Task_Second_Core with 
         Priority => System.Priority'Last - 1,
         CPU      => CPU'Last;

   task body End_Task_Second_Core is
      Next_Period : constant Ada.Real_Time.Time := Ada.Real_Time.Time_First + Ada.Real_Time.Microseconds (Experiments_Data.Delay_Time);
      Period_To_Add : constant Ada.Real_Time.Time_Span := Ada.Real_Time.Microseconds (10_000_000);
   begin
      delay until Next_Period + Period_To_Add;
      loop
         null;
      end loop;
   end End_Task_Second_Core;

end Periodic_Tasks;