pragma Warnings (Off);
with Ada.Text_IO;
with System.BB.Execution_Time;
pragma Warnings (On);

with System.BB.Protection;
with System.BB.Board_Support;
with System.BB.Threads.Queues;
with Mixed_Criticality_System;
with Core_Execution_Modes;

package body CPU_Budget_Monitor is

   procedure CPU_BE_Detected (E : in out Timing_Event) is
      use System.BB.Threads;
      use System.BB.Threads.Queues;
      use Mixed_Criticality_System;
      use Core_Execution_Modes;
      use System.BB.Board_Support.Multiprocessors;
      use System.Multiprocessors;
      --  use System.BB.Time;
      pragma Unreferenced (E);
      CPU_Id : constant CPU := Current_CPU;
      Self_Id : constant Thread_Id := Running_Thread;
      Task_Exceeded : constant System.Priority := Self_Id.Base_Priority;
      Cancelled : Boolean;
   begin
      System.BB.Protection.Enter_Kernel;
      Ada.Text_IO.Put ("CPU_" & System.Multiprocessors.CPU'Image (CPU_Id)
                               & ": task " & Integer'Image (Task_Exceeded));

      if Get_Core_Mode (CPU_Id) = LOW then
         if Self_Id.Criticality_Level = HIGH then
            Clear_Monitor (Cancelled);

            Ada.Text_IO.Put_Line
               (" HI-CRIT CPU_Budget_Exceeded DETECTED.");
            BE_Detected (Task_Exceeded) := (BE_Detected (Task_Exceeded) + 1);
            Set_Core_Mode (HIGH, CPU_Id);
            Enter_In_HI_Crit_Mode;

            Start_Monitor (Self_Id.Active_Budget);
         else
            Ada.Text_IO.Put_Line ("");
            Ada.Text_IO.Put_Line ("CPU_"
                           & System.Multiprocessors.CPU'Image (CPU_Id)
                           & ": GUILTY task " & Integer'Image (Task_Exceeded));

            Ada.Text_IO.Put_Line
                     ("-------------------------------------------------");
            Ada.Text_IO.Put_Line
                     ("--  LO-crit task exceeding its LO-crit budget  --");
            Ada.Text_IO.Put_Line
                     ("--        !!!  INVALID EXPERIMENTS  !!!        --");
            Ada.Text_IO.Put_Line
                     ("-------------------------------------------------");
            loop
               null;
            end loop;
         end if;
      else  --  Get_Core_Mode (CPU_Id) is HIGH
            Ada.Text_IO.Put_Line ("");
            Ada.Text_IO.Put_Line ("CPU_"
                           & System.Multiprocessors.CPU'Image (CPU_Id)
                           & ": GUILTY task " & Integer'Image (Task_Exceeded));
            Ada.Text_IO.Put_Line
               ("----------------------------------------------------------");
            Ada.Text_IO.Put_Line
               ("--        A task has exceeded its current budget        --");
            Ada.Text_IO.Put_Line
               ("--      Unpredictable overload during HI-crit mode      --");
            Ada.Text_IO.Put_Line
               ("--             !!!  INVALID EXPERIMENTS  !!!            --");
            Ada.Text_IO.Put_Line
               ("----------------------------------------------------------");
            loop
               null;
            end loop;
      end if;

      System.BB.Protection.Leave_Kernel;
      --  Ada.Text_IO.Put_Line ("BE HANDLED");
   end CPU_BE_Detected;

   procedure Start_Monitor (For_Time : System.BB.Time.Time_Span) is
      use Real_Time_No_Elab;
      use System.BB.Board_Support.Multiprocessors;
      use System.BB.Threads;
      use System.BB.Threads.Queues;
      CPU_Id : constant System.Multiprocessors.CPU := Current_CPU;
      Self_Id : constant Thread_Id := Running_Thread;
      --  Task_Exceeded : constant System.Priority := Self_Id.Base_Priority;
   begin
      Set_Handler
            (Event =>
                BE_Happened (CPU_Id),
            At_Time =>
                For_Time + Real_Time_No_Elab.Clock,
            Handler =>
                CPU_BE_Detected'Access);
      --  Ada.Text_IO.Put_Line (Integer'Image (Task_Exceeded) & " armed with"
      --                    & Duration'Image (To_Duration (For_Time)));

      Self_Id.T_Start := System.BB.Time.Clock;
   end Start_Monitor;

   procedure Clear_Monitor (Cancelled : out Boolean) is
      use System.BB.Board_Support.Multiprocessors;
      use System.BB.Threads;
      use System.BB.Time;
      use System.BB.Threads.Queues;
      CPU_Id : constant System.Multiprocessors.CPU := Current_CPU;
      Self_Id : constant Thread_Id := Running_Thread;
   begin
      Self_Id.T_Clear := System.BB.Time.Clock;

      Cancel_Handler
            (BE_Happened (CPU_Id), Cancelled);

      if Self_Id.Is_Monitored and Self_Id.State = Runnable then
         --  Ada.Text_IO.Put (Integer'Image (Self_Id.Base_Priority)
         --  & " consumed" & Duration'Image
         --  (System.BB.Time.To_Duration (Self_Id.Active_Budget)) & " => ");

         Self_Id.Active_Budget :=
                  Self_Id.Active_Budget - (Self_Id.T_Clear - Self_Id.T_Start);

         Ada.Text_IO.Put_Line (Duration'Image (System.BB.Time.To_Duration
                                             (Self_Id.Active_Budget)));
      end if;
   end Clear_Monitor;

end CPU_Budget_Monitor;
