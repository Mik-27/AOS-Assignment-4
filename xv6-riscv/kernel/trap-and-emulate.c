#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

// Struct to keep VM registers (Sample; feel free to change.)
struct vm_reg {
    int     code;
    int     mode;
    uint64  val;
};

// Keep the virtual state of the VM's privileged registers
struct vm_virtual_state {
    // User trap setup
    struct vm_reg ustatus;
    struct vm_reg utvec;
    struct vm_reg uie;
    struct vm_reg uip;

    // User trap handling
    struct vm_reg uscratch;
    struct vm_reg ucause;
    struct vm_reg utval;
    struct vm_reg uepc;

    // Supervisor trap setup
    struct vm_reg sstatus;
    struct vm_reg sedeleg;
    struct vm_reg sideleg;
    struct vm_reg stvec;
    struct vm_reg sie;
    struct vm_reg scounteren;

    // Supervisor trap handling
    struct vm_reg sscratch;
    struct vm_reg sepc;
    struct vm_reg scause;
    struct vm_reg stval;
    struct vm_reg sip;

    // Supervisor page table register
    struct vm_reg satp;

    // Machine information registers
    struct vm_reg mvendorid;
    struct vm_reg marchid;
    struct vm_reg mimpid;
    struct vm_reg mhartid;


    // Machine trap setup registers
    struct vm_reg misa;
    struct vm_reg mstatus;
    struct vm_reg mtvec;
    struct vm_reg medeleg;
    struct vm_reg mideleg;
    struct vm_reg mie;
    struct vm_reg mcounteren; 
    struct vm_reg mstatush;

    // Machine trap handling registers
    struct vm_reg mscratch;
    struct vm_reg mepc;
    struct vm_reg mtval;
    struct vm_reg mcause;
    struct vm_reg mip;

    struct vm_reg mtinst;
    struct vm_reg mtval2;

    bool pmp_enbaled;
    struct vm_reg pmpcgf[16];
    struct vm_reg pmpaddr[64];
    uint64 curr_mode;

    pagetable_t pseudo_pt;
    pagetable_t main_pt;
};

struct vm_virtual_state vm_state;

// In your ECALL, add the following for prints
// struct proc* p = myproc();
// printf("(EC at %p)\n", p->trapframe->epc);

void trap_and_emulate(void) {
    /* Comes here when a VM tries to execute a supervisor instruction. */

    /* Retrieve all required values from the instruction */
    uint64 addr     = 0;
    uint32 op       = 0;
    uint32 rd       = 0;
    uint32 funct3   = 0;
    uint32 rs1      = 0;
    uint32 uimm     = 0;

    /* Print the statement */
    printf("(PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                addr, op, rd, funct3, rs1, uimm);
}

void trap_and_emulate_init(void) {
    /* Create and initialize all state for the VM */
    vm_state.ustatus.code = 0x000;
    vm_state.ustatus.mode = 0;
    vm_state.ustatus.val = 0;

    vm_state.uie.code = 0x004;
    vm_state.uie.mode = 0;
    vm_state.uie.val = 0;

    vm_state.uscratch.code = 0x040;
    vm_state.uscratch.mode = 0;
    vm_state.uscratch.val = 0;

    vm_state.sstatus.code = 0x100;
    vm_state.sstatus.mode = 1;
    vm_state.sstatus.val = 0;

    vm_state.sedeleg.code = 0x102;
    vm_state.sedeleg.mode = 1;
    vm_state.sedeleg.val = 0;

    vm_state.sideleg.code = 0x103;
    vm_state.sideleg.mode = 1;
    vm_state.sideleg.val = 0;

    vm_state.sie.code = 0x104;
    vm_state.sie.mode = 1;
    vm_state.sie.val = 0;

    vm_state.stvec.code = 0x105;
    vm_state.stvec.mode = 1;
    vm_state.stvec.val = 0;

    vm_state.scounteren.code = 0x106;
    vm_state.scounteren.mode = 1;
    vm_state.scounteren.val = 0;

    vm_state.sscratch.code = 0x140;
    vm_state.sscratch.mode = 1;
    vm_state.sscratch.val = 0;

    vm_state.sepc.code = 0x141;
    vm_state.sepc.mode = 1;
    vm_state.sepc.val = 0;

    vm_state.scause.code = 0x142;
    vm_state.scause.mode = 1;
    vm_state.scause.val = 0;

    vm_state.stval.code = 0x143;
    vm_state.stval.mode = 1;
    vm_state.stval.val = 0;

    vm_state.sip.code = 0x144;
    vm_state.sip.mode = 1;
    vm_state.sip.val = 0;

    vm_state.satp.code = 0x180;
    vm_state.satp.mode = 1;
    vm_state.satp.val = 0;

    vm_state.mvendorid.code = 0xf11;
    vm_state.mvendorid.mode = 2;
    vm_state.mvendorid.val = 0x637365353336;

    vm_state.marchid.code = 0xf12;
    vm_state.marchid.mode = 2;
    vm_state.marchid.val = 0;

    vm_state.mimpid.code = 0xf13;
    vm_state.mimpid.mode = 2;
    vm_state.mimpid.val = 0;

    vm_state.mhartid.code = 0xf14;
    vm_state.mhartid.mode = 2;
    vm_state.mhartid.val = 0;

    vm_state.mstatus.code = 0x300;
    vm_state.mstatus.mode = 2;
    vm_state.mstatus.val = 0;

    vm_state.misa.code = 0x301;
    vm_state.misa.mode = 2;
    vm_state.misa.val = 0;

    vm_state.medeleg.code = 0x302;
    vm_state.medeleg.mode = 2;
    vm_state.medeleg.val = 0;

    vm_state.mideleg.code = 0x303;
    vm_state.mideleg.mode = 2;
    vm_state.mideleg.val = 0;

    vm_state.mie.code = 0x304;
    vm_state.mie.mode = 2;
    vm_state.mie.val = 0;

    vm_state.mtvec.code = 0x305;
    vm_state.mtvec.mode = 2;
    vm_state.mtvec.val = 0;

    vm_state.mcounteren.code = 0x306;
    vm_state.mcounteren.mode = 2;
    vm_state.mcounteren.val = 0;

    vm_state.mstatush.code = 0x310;
    vm_state.mstatush.mode = 2;
    vm_state.mstatush.val = 0;

    vm_state.mscratch.code = 0x340;
    vm_state.mscratch.mode = 2;
    vm_state.mscratch.val = 0;

    vm_state.mepc.code = 0x341;
    vm_state.mepc.mode = 2;
    vm_state.mepc.val = 0;

    vm_state.mcause.code = 0x342;
    vm_state.mcause.mode = 2;
    vm_state.mcause.val = 0;

    vm_state.mtval.code = 0x343;
    vm_state.mtval.mode = 2;
    vm_state.mtval.val = 0;

    vm_state.mip.code = 0x344;
    vm_state.mip.mode = 2;
    vm_state.mip.val = 0;

    vm_state.mtinst.code = 0x34a;
    vm_state.mtinst.mode = 2;
    vm_state.mtinst.val = 0;

    vm_state.mtval2.code = 0x34b;
    vm_state.mtval2.mode = 2;
    vm_state.mtval2.val = 0;
}