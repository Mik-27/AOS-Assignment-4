#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include "stdbool.h"
#include "stdlib.h"

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

    int pmp;
    struct vm_reg pmpcgf;
    struct vm_reg pmpaddr;
    uint64 curr_mode;
};

struct vm_virtual_state vm_state;

struct vm_reg find_reg(unsigned int uimm) {
    static struct vm_virtual_state v;

    if(uimm == 0x000)
        return v.ustatus;
    else if (uimm == 0x004)
        return v.uie;
    else if (uimm == 0x040)
        return v.uscratch;
    else if (uimm == 0x100)
        return v.sstatus;
    else if (uimm == 0x102)
        return v.sedeleg;
    else if (uimm == 0x103)
        return v.sideleg;
    else if (uimm == 0x104)
        return v.sie;
    else if (uimm == 0x105)
        return v.stvec;
    else if (uimm == 0x106)
        return v.scounteren;
    else if (uimm == 0x140)
        return v.sscratch;
    else if (uimm == 0x141)
        return v.sepc;
    else if (uimm == 0x142)
        return v.scause;
    else if (uimm == 0x143)
        return v.stval;
    else if (uimm == 0x144)
        return v.sip;
    else if (uimm == 0x180)
        return v.satp;
    else if (uimm == 0xF11)
        return v.mvendorid;
    else if (uimm == 0xF12)
        return v.marchid;
    else if (uimm == 0xF13)
        return v.mimpid;
    else if (uimm == 0xF14)
        return v.mhartid;
    else if (uimm == 0x300)
        return v.mstatus;
    else if (uimm == 0x301)
        return v.misa;
    else if (uimm == 0x302)
        return v.medeleg;
    else if (uimm == 0x303)
        return v.mideleg;
    else if (uimm == 0x304)
        return v.mie;
    else if (uimm == 0x305)
        return v.mtvec;
    else if (uimm == 0x306)
        return v.mcounteren;
    else if (uimm == 0x310)
        return v.mstatush;
    else if (uimm == 0x340)
        return v.mscratch;
    else if (uimm == 0x341)
        return v.mepc;
    else if (uimm == 0x342)
        return v.mcause;
    else if (uimm == 0x343)
        return v.mtval;
    else if (uimm == 0x344)
        return v.mip;
    else if (uimm == 0x34A)
        return v.mtinst;
    else if (uimm == 0x34B)
        return v.mtval2;
    else if (uimm == 0x3A0)
        return v.pmpcgf;
    else if (uimm == 0x3B0)
        return v.pmpaddr;
    else {
        struct vm_reg tmp;
        tmp.val = -1;
        return tmp;
    }
};

void trap_and_emulate(void) {
    /* Comes here when a VM tries to execute a supervisor instruction. */
    struct proc *p = myproc();

    /* Retrieve all required values from the instruction */
    uint64 addr    = r_sepc();
    char *pa = kalloc();
    copyin(p->pagetable, pa, addr, PGSIZE);
    uint32 inst     = *(uint32*)pa;
    uint32 op       = inst & 0x7F;
    uint32 rd       = (inst >> 7) & 0x1F;
    uint32 funct3   = (inst >> 12) & 0x7;
    uint32 rs1      = (inst >> 15) & 0x1F;
    uint32 uimm     = (inst >> 20) & 0xFFF;

    if(funct3 == 0x0) {
        if(uimm == 0x0) {
            // ECALL
            printf("ECALL (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                addr, op, rd, funct3, rs1, uimm);
            printf("(EC at %p)\n", p->trapframe->epc);

            if(vm_state.curr_mode == 0) {
                vm_state.curr_mode = 1;
                vm_state.sepc.val = p->trapframe->epc;
                p->trapframe->epc = vm_state.stvec.val;
            } 
            else if(vm_state.curr_mode == 1) {
                vm_state.mepc.val = p->trapframe->epc;
                vm_state.curr_mode = 2;
                p->trapframe->epc = vm_state.mtvec.val;
            }
        } 
        else if(uimm == 0x102) {
            // SRET
            if (vm_state.curr_mode > 0) {
                printf("SRET (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                    addr, op, rd, funct3, rs1, uimm);

                p->trapframe->epc = vm_state.sepc.val;
                vm_state.curr_mode = (vm_state.sstatus.val >> 8) & 0x1;
            }
            else {
                setkilled(p);
                trap_and_emulate_init();
            }
        }
        else if(uimm == 0x302) {
            // MRET
            if (vm_state.curr_mode > 1) {
                printf("MRET (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                    addr, op, rd, funct3, rs1, uimm);

                vm_state.curr_mode = (vm_state.mstatus.val >> 11) & 0x3;;
                p->trapframe->epc = vm_state.mepc.val;
            }
            else {
                setkilled(p);
                trap_and_emulate_init();
            }
        } else {
            setkilled(p);
            trap_and_emulate_init();
        }
    } 
    else if(funct3 == 0x1) {
        // CSRW
        printf("CSRW (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                addr, op, rd, funct3, rs1, uimm);
        struct vm_reg vr = find_reg(uimm);
        if(vr.val == -1){
            printf("Invalid Instruction");
            return;
        }
        if(vm_state.curr_mode >= vr.mode){
            uint64* rs1_p = &(p->trapframe->ra) + rs1 - 1;
            vr.val = *rs1_p;
        } else{
            setkilled(p);
            trap_and_emulate_init();
        }
        p->trapframe->epc += 4;
    } 
    else if (funct3 == 0x2) {
        // CSRR
        printf("CSRR (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
                addr, op, rd, funct3, rs1, uimm);
        struct vm_reg vr = find_reg(uimm);
        if(vr.val == -1) {
            printf("Invalid Instruction");
            return;
        }
        if(vm_state.curr_mode >= vr.mode){
            uint32 reg_val = vr.val;
            uint64* rd_p = &(p->trapframe->ra) + rd - 1;
            *rd_p = reg_val;  
        } else {
            setkilled(p);
            trap_and_emulate_init();
        }
        p->trapframe->epc += 4;
    } 
    else {
        printf("ERROR: Incorrect instruction");
        setkilled(p);
        trap_and_emulate_init();
    }

    kfree(pa);
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
    vm_state.mvendorid.val = 0xc5e536;

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

    vm_state.curr_mode = 2;
}