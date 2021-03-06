------------------------------------------------------------------------------
--                                                                          --
--                  GNAT RUN-TIME LIBRARY (GNARL) COMPONENTS                --
--                                                                          --
--                   S Y S T E M . B B . P R O T E C T I O N                --
--                                                                          --
--                                  B o d y                                 --
--                                                                          --
--        Copyright (C) 1999-2002 Universidad Politecnica de Madrid         --
--             Copyright (C) 2003-2005 The European Space Agency            --
--                     Copyright (C) 2003-2018, AdaCore                     --
--                                                                          --
-- GNARL is free software; you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion. GNARL is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNARL was developed by the GNARL team at Florida State University.       --
-- Extensive contributions were provided by Ada Core Technologies, Inc.     --
--                                                                          --
-- The port of GNARL to bare board targets was initially developed by the   --
-- Real-Time Systems Group at the Technical University of Madrid.           --
--                                                                          --
------------------------------------------------------------------------------

pragma Restrictions (No_Elaboration_Code);
with System.BB.CPU_Primitives;
with System.BB.Parameters;
with System.BB.Threads;
use System.BB.Threads;
with System.BB.Time;

with System.BB.Threads.Queues;
use System.BB.Threads.Queues;

with CPU_Budget_Monitor;

pragma Warnings (Off);
with Ada.Text_IO;
pragma Warnings (On);
--  The following pragma Elaborate is anomalous. We generally do not like
--  to use pragma Elaborate, since it disconnects the static elaboration
--  model checking (and generates a warning when using this model). So
--  either replace with Elaborate_All, or document why we need this and
--  why it is safe ???

pragma Warnings (Off);
pragma Elaborate (System.BB.Threads.Queues);
with System.BB.Execution_Time;
--  pragma Warnings (On);

with System.Tasking;
with System.Multiprocessors.Fair_Locks;
use System.Multiprocessors.Fair_Locks;
with System.Multiprocessors;
with System.BB.Board_Support;
with Real_Time_No_Elab;
--  with MBTA;

package body System.BB.Protection is

   ------------------
   -- Enter_Kernel --
   ------------------

   procedure Enter_Kernel is
   begin
      --  Interrupts are disabled to avoid concurrency problems when modifying
      --  kernel data. This way, external interrupts cannot be raised.

      CPU_Primitives.Disable_Interrupts;
   end Enter_Kernel;

   ------------------
   -- Leave_Kernel --
   ------------------

   procedure Leave_Kernel is
      pragma Warnings (Off);
      use System.BB.Time;
      use System.BB.Board_Support.Multiprocessors;
      use System.Multiprocessors;
      use type System.BB.Threads.Thread_States;
      Cancelled : Boolean := False;
      CPU_Id : constant CPU := Current_CPU;
      Start_Time : System.BB.Time.Time;
   begin
      --  Interrupts are always disabled when entering here

      --  Wake up served entry calls

      if Parameters.Multiprocessor
        and then Wakeup_Served_Entry_Callback /= null
      then
         Wakeup_Served_Entry_Callback.all;
      end if;

      --  The idle task is always runnable, so there is always a task to be
      --  run.

      --  We need to check whether a context switch is needed
      --  Lock (Ready_Tables_Locks (CPU_Id).all);

      if Threads.Queues.Context_Switch_Needed then
         --  Ada.Text_IO.Put_Line ("Leave_Kernel");
         Running_Thread.T_Clear := System.BB.Time.Clock;
         CPU_Budget_Monitor.Clear_Monitor (Cancelled);

         --  Perform a context switch because the currently executing thread
         --  is blocked or it is no longer the one with the highest priority.

         --  Update execution time before context switch

         if Scheduling_Event_Hook /= null then
            Scheduling_Event_Hook.all;
         end if;

         Start_Time := Clock;
         CPU_Primitives.Context_Switch;
         --  Ada.Text_IO.Put_Line ("Context Switch done!");
         --  Start budget monitoring iff the new running thread
         --  is NOT the idle thread and it has a budget
         --  (i.e. Is_Monitored = True).
         if (not (Running_Thread.Base_Priority = System.Tasking.Idle_Priority))
           and
             Running_Thread.Is_Monitored
         then
            --  MBTA.Log_RTE_Primitive_Duration
            --  (MBTA.CSW, To_Duration (Clock - Start_Time), CPU_Id);
            CPU_Budget_Monitor.Start_Monitor (Running_Thread.Active_Budget);
            Running_Thread.T_Start := System.BB.Time.Clock;
         end if;
      end if;

      --  There is always a running thread (at worst the idle thread)

      pragma Assert (Threads.Queues.Running_Thread.State = Threads.Runnable);

      Threads.Queues.Change_Release_Jitter (Threads.Queues.First_Thread);
      --  Unlock (Ready_Tables_Locks (CPU_Id).all);
      --  Now we need to set the hardware interrupt masking level equal to the
      --  software priority of the task that is executing.
      CPU_Primitives.Enable_Interrupts
        (Threads.Queues.Running_Thread.Active_Priority);

   end Leave_Kernel;

end System.BB.Protection;
