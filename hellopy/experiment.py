import os.path
import time

from threading import Thread

START_TIME = time.time()

from vix import VixHost, VixVm

with VixHost() as h:
    vmx_path = os.path.expanduser(
        "~/Virtual Machines.localized/vixpy-base.vmwarevm/vixpy-base.vmx")

    with VixVm(h, vmx_path) as base_vm:

        def do_stuff(i):
            def func():
                clone_path = os.path.expanduser(
                    "~/Virtual Machines.localized/vixpy-clone%d.vmwarevm/vixpy-clone%d.vmx" % (i, i))
                base_vm.clone(clone_path)

                with VixVm(h, clone_path) as child:
                    try:
                        child.power_on()
                        child.wait_for_tools()
                        guest = child.login('root', 'test')
                        print(guest.run_command("ip link"))
                    finally:
                        child.power_off()
                        child.delete()

            return func

        threads = []
        for i in range(0, 4):
            threads.append(Thread(target=do_stuff(i)))
        for t in threads:
            t.start()
        for t in threads:
            t.join()

END_TIME = time.time()

print("%.3fs elapsed" % (END_TIME - START_TIME))
