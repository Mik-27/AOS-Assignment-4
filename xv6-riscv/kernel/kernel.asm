
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	17010113          	addi	sp,sp,368 # 80009170 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	07a000ef          	jal	ra,80000090 <start>

000000008000001a <_entry_kernel>:
    8000001a:	6cf000ef          	jal	ra,80000ee8 <main>

000000008000001e <_entry_test>:
    8000001e:	a001                	j	8000001e <_entry_test>

0000000080000020 <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000020:	1141                	addi	sp,sp,-16
    80000022:	e422                	sd	s0,8(sp)
    80000024:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000026:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    8000002a:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002e:	0037979b          	slliw	a5,a5,0x3
    80000032:	02004737          	lui	a4,0x2004
    80000036:	97ba                	add	a5,a5,a4
    80000038:	0200c737          	lui	a4,0x200c
    8000003c:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000040:	000f4637          	lui	a2,0xf4
    80000044:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000048:	9732                	add	a4,a4,a2
    8000004a:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    8000004c:	00259693          	slli	a3,a1,0x2
    80000050:	96ae                	add	a3,a3,a1
    80000052:	068e                	slli	a3,a3,0x3
    80000054:	00009717          	auipc	a4,0x9
    80000058:	fdc70713          	addi	a4,a4,-36 # 80009030 <timer_scratch>
    8000005c:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005e:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    80000060:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000062:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000066:	00006797          	auipc	a5,0x6
    8000006a:	c4a78793          	addi	a5,a5,-950 # 80005cb0 <timervec>
    8000006e:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000072:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000076:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007a:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007e:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000082:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000086:	30479073          	csrw	mie,a5
}
    8000008a:	6422                	ld	s0,8(sp)
    8000008c:	0141                	addi	sp,sp,16
    8000008e:	8082                	ret

0000000080000090 <start>:
{
    80000090:	1141                	addi	sp,sp,-16
    80000092:	e406                	sd	ra,8(sp)
    80000094:	e022                	sd	s0,0(sp)
    80000096:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000098:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    8000009c:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000009e:	823e                	mv	tp,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000a0:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    800000a4:	7779                	lui	a4,0xffffe
    800000a6:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdbebf>
    800000aa:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000ac:	6705                	lui	a4,0x1
    800000ae:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000b4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000b8:	00001797          	auipc	a5,0x1
    800000bc:	e3078793          	addi	a5,a5,-464 # 80000ee8 <main>
    800000c0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000c4:	4781                	li	a5,0
    800000c6:	18079073          	csrw	satp,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ca:	57fd                	li	a5,-1
    800000cc:	83a9                	srli	a5,a5,0xa
    800000ce:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d2:	47bd                	li	a5,15
    800000d4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f48080e7          	jalr	-184(ra) # 80000020 <timerinit>
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000e0:	67c1                	lui	a5,0x10
    800000e2:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000e4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000e8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ec:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000f0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000f4:	10479073          	csrw	sie,a5
  asm volatile("mret");
    800000f8:	30200073          	mret
}
    800000fc:	60a2                	ld	ra,8(sp)
    800000fe:	6402                	ld	s0,0(sp)
    80000100:	0141                	addi	sp,sp,16
    80000102:	8082                	ret

0000000080000104 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000104:	715d                	addi	sp,sp,-80
    80000106:	e486                	sd	ra,72(sp)
    80000108:	e0a2                	sd	s0,64(sp)
    8000010a:	fc26                	sd	s1,56(sp)
    8000010c:	f84a                	sd	s2,48(sp)
    8000010e:	f44e                	sd	s3,40(sp)
    80000110:	f052                	sd	s4,32(sp)
    80000112:	ec56                	sd	s5,24(sp)
    80000114:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000116:	04c05763          	blez	a2,80000164 <consolewrite+0x60>
    8000011a:	8a2a                	mv	s4,a0
    8000011c:	84ae                	mv	s1,a1
    8000011e:	89b2                	mv	s3,a2
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	42a080e7          	jalr	1066(ra) # 80002558 <either_copyin>
    80000136:	01550d63          	beq	a0,s5,80000150 <consolewrite+0x4c>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7f2080e7          	jalr	2034(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x20>
    8000014e:	894e                	mv	s2,s3
  }

  return i;
}
    80000150:	854a                	mv	a0,s2
    80000152:	60a6                	ld	ra,72(sp)
    80000154:	6406                	ld	s0,64(sp)
    80000156:	74e2                	ld	s1,56(sp)
    80000158:	7942                	ld	s2,48(sp)
    8000015a:	79a2                	ld	s3,40(sp)
    8000015c:	7a02                	ld	s4,32(sp)
    8000015e:	6ae2                	ld	s5,24(sp)
    80000160:	6161                	addi	sp,sp,80
    80000162:	8082                	ret
  for(i = 0; i < n; i++){
    80000164:	4901                	li	s2,0
    80000166:	b7ed                	j	80000150 <consolewrite+0x4c>

0000000080000168 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000168:	711d                	addi	sp,sp,-96
    8000016a:	ec86                	sd	ra,88(sp)
    8000016c:	e8a2                	sd	s0,80(sp)
    8000016e:	e4a6                	sd	s1,72(sp)
    80000170:	e0ca                	sd	s2,64(sp)
    80000172:	fc4e                	sd	s3,56(sp)
    80000174:	f852                	sd	s4,48(sp)
    80000176:	f456                	sd	s5,40(sp)
    80000178:	f05a                	sd	s6,32(sp)
    8000017a:	ec5e                	sd	s7,24(sp)
    8000017c:	1080                	addi	s0,sp,96
    8000017e:	8aaa                	mv	s5,a0
    80000180:	8a2e                	mv	s4,a1
    80000182:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000184:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000188:	00011517          	auipc	a0,0x11
    8000018c:	fe850513          	addi	a0,a0,-24 # 80011170 <cons>
    80000190:	00001097          	auipc	ra,0x1
    80000194:	ab8080e7          	jalr	-1352(ra) # 80000c48 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00011497          	auipc	s1,0x11
    8000019c:	fd848493          	addi	s1,s1,-40 # 80011170 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00011917          	auipc	s2,0x11
    800001a4:	06890913          	addi	s2,s2,104 # 80011208 <cons+0x98>
  while(n > 0){
    800001a8:	09305263          	blez	s3,8000022c <consoleread+0xc4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	02f71763          	bne	a4,a5,800001e2 <consoleread+0x7a>
      if(killed(myproc())){
    800001b8:	00002097          	auipc	ra,0x2
    800001bc:	86c080e7          	jalr	-1940(ra) # 80001a24 <myproc>
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	1e2080e7          	jalr	482(ra) # 800023a2 <killed>
    800001c8:	ed2d                	bnez	a0,80000242 <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001ca:	85a6                	mv	a1,s1
    800001cc:	854a                	mv	a0,s2
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	f2c080e7          	jalr	-212(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001d6:	0984a783          	lw	a5,152(s1)
    800001da:	09c4a703          	lw	a4,156(s1)
    800001de:	fcf70de3          	beq	a4,a5,800001b8 <consoleread+0x50>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e2:	00011717          	auipc	a4,0x11
    800001e6:	f8e70713          	addi	a4,a4,-114 # 80011170 <cons>
    800001ea:	0017869b          	addiw	a3,a5,1
    800001ee:	08d72c23          	sw	a3,152(a4)
    800001f2:	07f7f693          	andi	a3,a5,127
    800001f6:	9736                	add	a4,a4,a3
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000200:	4691                	li	a3,4
    80000202:	06db8463          	beq	s7,a3,8000026a <consoleread+0x102>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000206:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020a:	4685                	li	a3,1
    8000020c:	faf40613          	addi	a2,s0,-81
    80000210:	85d2                	mv	a1,s4
    80000212:	8556                	mv	a0,s5
    80000214:	00002097          	auipc	ra,0x2
    80000218:	2ee080e7          	jalr	750(ra) # 80002502 <either_copyout>
    8000021c:	57fd                	li	a5,-1
    8000021e:	00f50763          	beq	a0,a5,8000022c <consoleread+0xc4>
      break;

    dst++;
    80000222:	0a05                	addi	s4,s4,1
    --n;
    80000224:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000226:	47a9                	li	a5,10
    80000228:	f8fb90e3          	bne	s7,a5,800001a8 <consoleread+0x40>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f4450513          	addi	a0,a0,-188 # 80011170 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	ac8080e7          	jalr	-1336(ra) # 80000cfc <release>

  return target - n;
    8000023c:	413b053b          	subw	a0,s6,s3
    80000240:	a811                	j	80000254 <consoleread+0xec>
        release(&cons.lock);
    80000242:	00011517          	auipc	a0,0x11
    80000246:	f2e50513          	addi	a0,a0,-210 # 80011170 <cons>
    8000024a:	00001097          	auipc	ra,0x1
    8000024e:	ab2080e7          	jalr	-1358(ra) # 80000cfc <release>
        return -1;
    80000252:	557d                	li	a0,-1
}
    80000254:	60e6                	ld	ra,88(sp)
    80000256:	6446                	ld	s0,80(sp)
    80000258:	64a6                	ld	s1,72(sp)
    8000025a:	6906                	ld	s2,64(sp)
    8000025c:	79e2                	ld	s3,56(sp)
    8000025e:	7a42                	ld	s4,48(sp)
    80000260:	7aa2                	ld	s5,40(sp)
    80000262:	7b02                	ld	s6,32(sp)
    80000264:	6be2                	ld	s7,24(sp)
    80000266:	6125                	addi	sp,sp,96
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677fe3          	bgeu	a4,s6,8000022c <consoleread+0xc4>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	f8f72b23          	sw	a5,-106(a4) # 80011208 <cons+0x98>
    8000027a:	bf4d                	j	8000022c <consoleread+0xc4>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	5de080e7          	jalr	1502(ra) # 8000086a <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	5cc080e7          	jalr	1484(ra) # 8000086a <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	5c0080e7          	jalr	1472(ra) # 8000086a <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5b6080e7          	jalr	1462(ra) # 8000086a <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	ea450513          	addi	a0,a0,-348 # 80011170 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	974080e7          	jalr	-1676(ra) # 80000c48 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2bc080e7          	jalr	700(ra) # 800025ae <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e7650513          	addi	a0,a0,-394 # 80011170 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9fa080e7          	jalr	-1542(ra) # 80000cfc <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e5270713          	addi	a4,a4,-430 # 80011170 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e2878793          	addi	a5,a5,-472 # 80011170 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	e927a783          	lw	a5,-366(a5) # 80011208 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	de670713          	addi	a4,a4,-538 # 80011170 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	dd648493          	addi	s1,s1,-554 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	d9a70713          	addi	a4,a4,-614 # 80011170 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72223          	sw	a5,-476(a4) # 80011210 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d5e78793          	addi	a5,a5,-674 # 80011170 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dcc7ab23          	sw	a2,-554(a5) # 8001120c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dca50513          	addi	a0,a0,-566 # 80011208 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d18080e7          	jalr	-744(ra) # 8000215e <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d1050513          	addi	a0,a0,-752 # 80011170 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	750080e7          	jalr	1872(ra) # 80000bb8 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	3aa080e7          	jalr	938(ra) # 8000081a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	09078793          	addi	a5,a5,144 # 80021508 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce870713          	addi	a4,a4,-792 # 80000168 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7a70713          	addi	a4,a4,-902 # 80000104 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
  //   release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	ce07a223          	sw	zero,-796(a5) # 80011230 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	a6f72823          	sw	a5,-1424(a4) # 80008ff0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  if (fmt == 0)
    800005ba:	c90d                	beqz	a0,800005ec <printf+0x62>
    800005bc:	8a2a                	mv	s4,a0
  va_start(ap, fmt);
    800005be:	00840793          	addi	a5,s0,8
    800005c2:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c6:	00054503          	lbu	a0,0(a0)
    800005ca:	20050063          	beqz	a0,800007ca <printf+0x240>
    800005ce:	4481                	li	s1,0
    if(c != '%'){
    800005d0:	02500b13          	li	s6,37
    switch(c){
    800005d4:	07000b93          	li	s7,112
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008a97          	auipc	s5,0x8
    800005dc:	a68a8a93          	addi	s5,s5,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	03400c13          	li	s8,52
  } while((x /= base) != 0);
    800005e8:	4d3d                	li	s10,15
    800005ea:	a025                	j	80000612 <printf+0x88>
    panic("null fmt");
    800005ec:	00008517          	auipc	a0,0x8
    800005f0:	a3c50513          	addi	a0,a0,-1476 # 80008028 <etext+0x28>
    800005f4:	00000097          	auipc	ra,0x0
    800005f8:	f4c080e7          	jalr	-180(ra) # 80000540 <panic>
      consputc(c);
    800005fc:	00000097          	auipc	ra,0x0
    80000600:	c80080e7          	jalr	-896(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000604:	2485                	addiw	s1,s1,1
    80000606:	009a07b3          	add	a5,s4,s1
    8000060a:	0007c503          	lbu	a0,0(a5)
    8000060e:	1a050e63          	beqz	a0,800007ca <printf+0x240>
    if(c != '%'){
    80000612:	ff6515e3          	bne	a0,s6,800005fc <printf+0x72>
    c = fmt[++i] & 0xff;
    80000616:	2485                	addiw	s1,s1,1
    80000618:	009a07b3          	add	a5,s4,s1
    8000061c:	0007c783          	lbu	a5,0(a5)
    80000620:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000624:	1a078363          	beqz	a5,800007ca <printf+0x240>
    switch(c){
    80000628:	11778563          	beq	a5,s7,80000732 <printf+0x1a8>
    8000062c:	02fbee63          	bltu	s7,a5,80000668 <printf+0xde>
    80000630:	07878063          	beq	a5,s8,80000690 <printf+0x106>
    80000634:	06400713          	li	a4,100
    80000638:	02e79063          	bne	a5,a4,80000658 <printf+0xce>
      printint(va_arg(ap, int), 10, 1);
    8000063c:	f8843783          	ld	a5,-120(s0)
    80000640:	00878713          	addi	a4,a5,8
    80000644:	f8e43423          	sd	a4,-120(s0)
    80000648:	4605                	li	a2,1
    8000064a:	45a9                	li	a1,10
    8000064c:	4388                	lw	a0,0(a5)
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	e4e080e7          	jalr	-434(ra) # 8000049c <printint>
      break;
    80000656:	b77d                	j	80000604 <printf+0x7a>
    switch(c){
    80000658:	15679e63          	bne	a5,s6,800007b4 <printf+0x22a>
      consputc('%');
    8000065c:	855a                	mv	a0,s6
    8000065e:	00000097          	auipc	ra,0x0
    80000662:	c1e080e7          	jalr	-994(ra) # 8000027c <consputc>
      break;
    80000666:	bf79                	j	80000604 <printf+0x7a>
    switch(c){
    80000668:	11978863          	beq	a5,s9,80000778 <printf+0x1ee>
    8000066c:	07800713          	li	a4,120
    80000670:	14e79263          	bne	a5,a4,800007b4 <printf+0x22a>
      printint(va_arg(ap, int), 16, 1);
    80000674:	f8843783          	ld	a5,-120(s0)
    80000678:	00878713          	addi	a4,a5,8
    8000067c:	f8e43423          	sd	a4,-120(s0)
    80000680:	4605                	li	a2,1
    80000682:	45c1                	li	a1,16
    80000684:	4388                	lw	a0,0(a5)
    80000686:	00000097          	auipc	ra,0x0
    8000068a:	e16080e7          	jalr	-490(ra) # 8000049c <printint>
      break;
    8000068e:	bf9d                	j	80000604 <printf+0x7a>
      print4hex(va_arg(ap, int), 16, 1);
    80000690:	f8843783          	ld	a5,-120(s0)
    80000694:	00878713          	addi	a4,a5,8
    80000698:	f8e43423          	sd	a4,-120(s0)
    8000069c:	438c                	lw	a1,0(a5)
    x = xx;
    8000069e:	0005879b          	sext.w	a5,a1
  if(sign && (sign = xx < 0))
    800006a2:	0805c563          	bltz	a1,8000072c <printf+0x1a2>
    800006a6:	f8040693          	addi	a3,s0,-128
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006aa:	4901                	li	s2,0
    buf[i++] = digits[x % base];
    800006ac:	864a                	mv	a2,s2
    800006ae:	2905                	addiw	s2,s2,1
    800006b0:	00f7f713          	andi	a4,a5,15
    800006b4:	9756                	add	a4,a4,s5
    800006b6:	00074703          	lbu	a4,0(a4)
    800006ba:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800006be:	0007871b          	sext.w	a4,a5
    800006c2:	0047d79b          	srliw	a5,a5,0x4
    800006c6:	0685                	addi	a3,a3,1
    800006c8:	feed62e3          	bltu	s10,a4,800006ac <printf+0x122>
  if(sign)
    800006cc:	0005dc63          	bgez	a1,800006e4 <printf+0x15a>
    buf[i++] = '-';
    800006d0:	f9090793          	addi	a5,s2,-112
    800006d4:	00878933          	add	s2,a5,s0
    800006d8:	02d00793          	li	a5,45
    800006dc:	fef90823          	sb	a5,-16(s2)
    800006e0:	0026091b          	addiw	s2,a2,2
  for (int p=4-i; p>=0; p--)
    800006e4:	4991                	li	s3,4
    800006e6:	412989bb          	subw	s3,s3,s2
    800006ea:	0009cc63          	bltz	s3,80000702 <printf+0x178>
    800006ee:	5dfd                	li	s11,-1
    consputc('0');
    800006f0:	03000513          	li	a0,48
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
  for (int p=4-i; p>=0; p--)
    800006fc:	39fd                	addiw	s3,s3,-1
    800006fe:	ffb999e3          	bne	s3,s11,800006f0 <printf+0x166>
  while(--i >= 0)
    80000702:	fff9099b          	addiw	s3,s2,-1
    80000706:	f609c7e3          	bltz	s3,80000674 <printf+0xea>
    8000070a:	f9090793          	addi	a5,s2,-112
    8000070e:	00878933          	add	s2,a5,s0
    80000712:	193d                	addi	s2,s2,-17
    80000714:	5dfd                	li	s11,-1
    consputc(buf[i]);
    80000716:	00094503          	lbu	a0,0(s2)
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000722:	39fd                	addiw	s3,s3,-1
    80000724:	197d                	addi	s2,s2,-1
    80000726:	ffb998e3          	bne	s3,s11,80000716 <printf+0x18c>
    8000072a:	b7a9                	j	80000674 <printf+0xea>
    x = -xx;
    8000072c:	40b007bb          	negw	a5,a1
    80000730:	bf9d                	j	800006a6 <printf+0x11c>
      printptr(va_arg(ap, uint64));
    80000732:	f8843783          	ld	a5,-120(s0)
    80000736:	00878713          	addi	a4,a5,8
    8000073a:	f8e43423          	sd	a4,-120(s0)
    8000073e:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000742:	03000513          	li	a0,48
    80000746:	00000097          	auipc	ra,0x0
    8000074a:	b36080e7          	jalr	-1226(ra) # 8000027c <consputc>
  consputc('x');
    8000074e:	07800513          	li	a0,120
    80000752:	00000097          	auipc	ra,0x0
    80000756:	b2a080e7          	jalr	-1238(ra) # 8000027c <consputc>
    8000075a:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000075c:	03c9d793          	srli	a5,s3,0x3c
    80000760:	97d6                	add	a5,a5,s5
    80000762:	0007c503          	lbu	a0,0(a5)
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b16080e7          	jalr	-1258(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000076e:	0992                	slli	s3,s3,0x4
    80000770:	397d                	addiw	s2,s2,-1
    80000772:	fe0915e3          	bnez	s2,8000075c <printf+0x1d2>
    80000776:	b579                	j	80000604 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    80000778:	f8843783          	ld	a5,-120(s0)
    8000077c:	00878713          	addi	a4,a5,8
    80000780:	f8e43423          	sd	a4,-120(s0)
    80000784:	0007b903          	ld	s2,0(a5)
    80000788:	00090f63          	beqz	s2,800007a6 <printf+0x21c>
      for(; *s; s++)
    8000078c:	00094503          	lbu	a0,0(s2)
    80000790:	e6050ae3          	beqz	a0,80000604 <printf+0x7a>
        consputc(*s);
    80000794:	00000097          	auipc	ra,0x0
    80000798:	ae8080e7          	jalr	-1304(ra) # 8000027c <consputc>
      for(; *s; s++)
    8000079c:	0905                	addi	s2,s2,1
    8000079e:	00094503          	lbu	a0,0(s2)
    800007a2:	f96d                	bnez	a0,80000794 <printf+0x20a>
    800007a4:	b585                	j	80000604 <printf+0x7a>
        s = "(null)";
    800007a6:	00008917          	auipc	s2,0x8
    800007aa:	87a90913          	addi	s2,s2,-1926 # 80008020 <etext+0x20>
      for(; *s; s++)
    800007ae:	02800513          	li	a0,40
    800007b2:	b7cd                	j	80000794 <printf+0x20a>
      consputc('%');
    800007b4:	855a                	mv	a0,s6
    800007b6:	00000097          	auipc	ra,0x0
    800007ba:	ac6080e7          	jalr	-1338(ra) # 8000027c <consputc>
      consputc(c);
    800007be:	854a                	mv	a0,s2
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	abc080e7          	jalr	-1348(ra) # 8000027c <consputc>
      break;
    800007c8:	bd35                	j	80000604 <printf+0x7a>
}
    800007ca:	70e6                	ld	ra,120(sp)
    800007cc:	7446                	ld	s0,112(sp)
    800007ce:	74a6                	ld	s1,104(sp)
    800007d0:	7906                	ld	s2,96(sp)
    800007d2:	69e6                	ld	s3,88(sp)
    800007d4:	6a46                	ld	s4,80(sp)
    800007d6:	6aa6                	ld	s5,72(sp)
    800007d8:	6b06                	ld	s6,64(sp)
    800007da:	7be2                	ld	s7,56(sp)
    800007dc:	7c42                	ld	s8,48(sp)
    800007de:	7ca2                	ld	s9,40(sp)
    800007e0:	7d02                	ld	s10,32(sp)
    800007e2:	6de2                	ld	s11,24(sp)
    800007e4:	6129                	addi	sp,sp,192
    800007e6:	8082                	ret

00000000800007e8 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007e8:	1101                	addi	sp,sp,-32
    800007ea:	ec06                	sd	ra,24(sp)
    800007ec:	e822                	sd	s0,16(sp)
    800007ee:	e426                	sd	s1,8(sp)
    800007f0:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f2:	00011497          	auipc	s1,0x11
    800007f6:	a2648493          	addi	s1,s1,-1498 # 80011218 <pr>
    800007fa:	00008597          	auipc	a1,0x8
    800007fe:	83e58593          	addi	a1,a1,-1986 # 80008038 <etext+0x38>
    80000802:	8526                	mv	a0,s1
    80000804:	00000097          	auipc	ra,0x0
    80000808:	3b4080e7          	jalr	948(ra) # 80000bb8 <initlock>
  pr.locking = 1;
    8000080c:	4785                	li	a5,1
    8000080e:	cc9c                	sw	a5,24(s1)
}
    80000810:	60e2                	ld	ra,24(sp)
    80000812:	6442                	ld	s0,16(sp)
    80000814:	64a2                	ld	s1,8(sp)
    80000816:	6105                	addi	sp,sp,32
    80000818:	8082                	ret

000000008000081a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081a:	1141                	addi	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000822:	100007b7          	lui	a5,0x10000
    80000826:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082a:	f8000713          	li	a4,-128
    8000082e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000832:	470d                	li	a4,3
    80000834:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000838:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000083c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000840:	469d                	li	a3,7
    80000842:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000846:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084a:	00008597          	auipc	a1,0x8
    8000084e:	80e58593          	addi	a1,a1,-2034 # 80008058 <digits+0x18>
    80000852:	00011517          	auipc	a0,0x11
    80000856:	9e650513          	addi	a0,a0,-1562 # 80011238 <uart_tx_lock>
    8000085a:	00000097          	auipc	ra,0x0
    8000085e:	35e080e7          	jalr	862(ra) # 80000bb8 <initlock>
}
    80000862:	60a2                	ld	ra,8(sp)
    80000864:	6402                	ld	s0,0(sp)
    80000866:	0141                	addi	sp,sp,16
    80000868:	8082                	ret

000000008000086a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086a:	1101                	addi	sp,sp,-32
    8000086c:	ec06                	sd	ra,24(sp)
    8000086e:	e822                	sd	s0,16(sp)
    80000870:	e426                	sd	s1,8(sp)
    80000872:	1000                	addi	s0,sp,32
    80000874:	84aa                	mv	s1,a0
  push_off();
    80000876:	00000097          	auipc	ra,0x0
    8000087a:	386080e7          	jalr	902(ra) # 80000bfc <push_off>
  //   for(;;)
  //     ;
  // }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087e:	10000737          	lui	a4,0x10000
    80000882:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000886:	0207f793          	andi	a5,a5,32
    8000088a:	dfe5                	beqz	a5,80000882 <uartputc_sync+0x18>
    ;
  WriteReg(THR, c);
    8000088c:	0ff4f493          	zext.b	s1,s1
    80000890:	100007b7          	lui	a5,0x10000
    80000894:	00978023          	sb	s1,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000898:	00000097          	auipc	ra,0x0
    8000089c:	404080e7          	jalr	1028(ra) # 80000c9c <pop_off>
}
    800008a0:	60e2                	ld	ra,24(sp)
    800008a2:	6442                	ld	s0,16(sp)
    800008a4:	64a2                	ld	s1,8(sp)
    800008a6:	6105                	addi	sp,sp,32
    800008a8:	8082                	ret

00000000800008aa <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008aa:	00008797          	auipc	a5,0x8
    800008ae:	74e7b783          	ld	a5,1870(a5) # 80008ff8 <uart_tx_r>
    800008b2:	00008717          	auipc	a4,0x8
    800008b6:	74e73703          	ld	a4,1870(a4) # 80009000 <uart_tx_w>
    800008ba:	06f70a63          	beq	a4,a5,8000092e <uartstart+0x84>
{
    800008be:	7139                	addi	sp,sp,-64
    800008c0:	fc06                	sd	ra,56(sp)
    800008c2:	f822                	sd	s0,48(sp)
    800008c4:	f426                	sd	s1,40(sp)
    800008c6:	f04a                	sd	s2,32(sp)
    800008c8:	ec4e                	sd	s3,24(sp)
    800008ca:	e852                	sd	s4,16(sp)
    800008cc:	e456                	sd	s5,8(sp)
    800008ce:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008d4:	00011a17          	auipc	s4,0x11
    800008d8:	964a0a13          	addi	s4,s4,-1692 # 80011238 <uart_tx_lock>
    uart_tx_r += 1;
    800008dc:	00008497          	auipc	s1,0x8
    800008e0:	71c48493          	addi	s1,s1,1820 # 80008ff8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e4:	00008997          	auipc	s3,0x8
    800008e8:	71c98993          	addi	s3,s3,1820 # 80009000 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008ec:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008f0:	02077713          	andi	a4,a4,32
    800008f4:	c705                	beqz	a4,8000091c <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008f6:	01f7f713          	andi	a4,a5,31
    800008fa:	9752                	add	a4,a4,s4
    800008fc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000900:	0785                	addi	a5,a5,1
    80000902:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	858080e7          	jalr	-1960(ra) # 8000215e <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	609c                	ld	a5,0(s1)
    80000914:	0009b703          	ld	a4,0(s3)
    80000918:	fcf71ae3          	bne	a4,a5,800008ec <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000942:	00011517          	auipc	a0,0x11
    80000946:	8f650513          	addi	a0,a0,-1802 # 80011238 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	2fe080e7          	jalr	766(ra) # 80000c48 <acquire>
  if(panicked){
    80000952:	00008797          	auipc	a5,0x8
    80000956:	69e7a783          	lw	a5,1694(a5) # 80008ff0 <panicked>
    8000095a:	e7c9                	bnez	a5,800009e4 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00008717          	auipc	a4,0x8
    80000960:	6a473703          	ld	a4,1700(a4) # 80009000 <uart_tx_w>
    80000964:	00008797          	auipc	a5,0x8
    80000968:	6947b783          	ld	a5,1684(a5) # 80008ff8 <uart_tx_r>
    8000096c:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000970:	00011997          	auipc	s3,0x11
    80000974:	8c898993          	addi	s3,s3,-1848 # 80011238 <uart_tx_lock>
    80000978:	00008497          	auipc	s1,0x8
    8000097c:	68048493          	addi	s1,s1,1664 # 80008ff8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000980:	00008917          	auipc	s2,0x8
    80000984:	68090913          	addi	s2,s2,1664 # 80009000 <uart_tx_w>
    80000988:	00e79f63          	bne	a5,a4,800009a6 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000098c:	85ce                	mv	a1,s3
    8000098e:	8526                	mv	a0,s1
    80000990:	00001097          	auipc	ra,0x1
    80000994:	76a080e7          	jalr	1898(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000998:	00093703          	ld	a4,0(s2)
    8000099c:	609c                	ld	a5,0(s1)
    8000099e:	02078793          	addi	a5,a5,32
    800009a2:	fee785e3          	beq	a5,a4,8000098c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    800009a6:	00011497          	auipc	s1,0x11
    800009aa:	89248493          	addi	s1,s1,-1902 # 80011238 <uart_tx_lock>
    800009ae:	01f77793          	andi	a5,a4,31
    800009b2:	97a6                	add	a5,a5,s1
    800009b4:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009b8:	0705                	addi	a4,a4,1
    800009ba:	00008797          	auipc	a5,0x8
    800009be:	64e7b323          	sd	a4,1606(a5) # 80009000 <uart_tx_w>
  uartstart();
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	ee8080e7          	jalr	-280(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    800009ca:	8526                	mv	a0,s1
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	330080e7          	jalr	816(ra) # 80000cfc <release>
}
    800009d4:	70a2                	ld	ra,40(sp)
    800009d6:	7402                	ld	s0,32(sp)
    800009d8:	64e2                	ld	s1,24(sp)
    800009da:	6942                	ld	s2,16(sp)
    800009dc:	69a2                	ld	s3,8(sp)
    800009de:	6a02                	ld	s4,0(sp)
    800009e0:	6145                	addi	sp,sp,48
    800009e2:	8082                	ret
    for(;;)
    800009e4:	a001                	j	800009e4 <uartputc+0xb4>

00000000800009e6 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009e6:	1141                	addi	sp,sp,-16
    800009e8:	e422                	sd	s0,8(sp)
    800009ea:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ec:	100007b7          	lui	a5,0x10000
    800009f0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009f4:	8b85                	andi	a5,a5,1
    800009f6:	cb81                	beqz	a5,80000a06 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    800009f8:	100007b7          	lui	a5,0x10000
    800009fc:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    80000a00:	6422                	ld	s0,8(sp)
    80000a02:	0141                	addi	sp,sp,16
    80000a04:	8082                	ret
    return -1;
    80000a06:	557d                	li	a0,-1
    80000a08:	bfe5                	j	80000a00 <uartgetc+0x1a>

0000000080000a0a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000a0a:	1101                	addi	sp,sp,-32
    80000a0c:	ec06                	sd	ra,24(sp)
    80000a0e:	e822                	sd	s0,16(sp)
    80000a10:	e426                	sd	s1,8(sp)
    80000a12:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a14:	54fd                	li	s1,-1
    80000a16:	a029                	j	80000a20 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	8a6080e7          	jalr	-1882(ra) # 800002be <consoleintr>
    int c = uartgetc();
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	fc6080e7          	jalr	-58(ra) # 800009e6 <uartgetc>
    if(c == -1)
    80000a28:	fe9518e3          	bne	a0,s1,80000a18 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a2c:	00011497          	auipc	s1,0x11
    80000a30:	80c48493          	addi	s1,s1,-2036 # 80011238 <uart_tx_lock>
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	212080e7          	jalr	530(ra) # 80000c48 <acquire>
  uartstart();
    80000a3e:	00000097          	auipc	ra,0x0
    80000a42:	e6c080e7          	jalr	-404(ra) # 800008aa <uartstart>
  release(&uart_tx_lock);
    80000a46:	8526                	mv	a0,s1
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	2b4080e7          	jalr	692(ra) # 80000cfc <release>
}
    80000a50:	60e2                	ld	ra,24(sp)
    80000a52:	6442                	ld	s0,16(sp)
    80000a54:	64a2                	ld	s1,8(sp)
    80000a56:	6105                	addi	sp,sp,32
    80000a58:	8082                	ret

0000000080000a5a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a5a:	1101                	addi	sp,sp,-32
    80000a5c:	ec06                	sd	ra,24(sp)
    80000a5e:	e822                	sd	s0,16(sp)
    80000a60:	e426                	sd	s1,8(sp)
    80000a62:	e04a                	sd	s2,0(sp)
    80000a64:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a66:	03451793          	slli	a5,a0,0x34
    80000a6a:	ebb9                	bnez	a5,80000ac0 <kfree+0x66>
    80000a6c:	84aa                	mv	s1,a0
    80000a6e:	00022797          	auipc	a5,0x22
    80000a72:	ed278793          	addi	a5,a5,-302 # 80022940 <end>
    80000a76:	04f56563          	bltu	a0,a5,80000ac0 <kfree+0x66>
    80000a7a:	47c5                	li	a5,17
    80000a7c:	07ee                	slli	a5,a5,0x1b
    80000a7e:	04f57163          	bgeu	a0,a5,80000ac0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a82:	6605                	lui	a2,0x1
    80000a84:	4585                	li	a1,1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2be080e7          	jalr	702(ra) # 80000d44 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a8e:	00010917          	auipc	s2,0x10
    80000a92:	7e290913          	addi	s2,s2,2018 # 80011270 <kmem>
    80000a96:	854a                	mv	a0,s2
    80000a98:	00000097          	auipc	ra,0x0
    80000a9c:	1b0080e7          	jalr	432(ra) # 80000c48 <acquire>
  r->next = kmem.freelist;
    80000aa0:	01893783          	ld	a5,24(s2)
    80000aa4:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000aa6:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000aaa:	854a                	mv	a0,s2
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	250080e7          	jalr	592(ra) # 80000cfc <release>
}
    80000ab4:	60e2                	ld	ra,24(sp)
    80000ab6:	6442                	ld	s0,16(sp)
    80000ab8:	64a2                	ld	s1,8(sp)
    80000aba:	6902                	ld	s2,0(sp)
    80000abc:	6105                	addi	sp,sp,32
    80000abe:	8082                	ret
    panic("kfree");
    80000ac0:	00007517          	auipc	a0,0x7
    80000ac4:	5a050513          	addi	a0,a0,1440 # 80008060 <digits+0x20>
    80000ac8:	00000097          	auipc	ra,0x0
    80000acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080000ad0 <freerange>:
{
    80000ad0:	7179                	addi	sp,sp,-48
    80000ad2:	f406                	sd	ra,40(sp)
    80000ad4:	f022                	sd	s0,32(sp)
    80000ad6:	ec26                	sd	s1,24(sp)
    80000ad8:	e84a                	sd	s2,16(sp)
    80000ada:	e44e                	sd	s3,8(sp)
    80000adc:	e052                	sd	s4,0(sp)
    80000ade:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae0:	6785                	lui	a5,0x1
    80000ae2:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ae6:	00e504b3          	add	s1,a0,a4
    80000aea:	777d                	lui	a4,0xfffff
    80000aec:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3c>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f5c080e7          	jalr	-164(ra) # 80000a5a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x2a>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	1141                	addi	sp,sp,-16
    80000b1e:	e406                	sd	ra,8(sp)
    80000b20:	e022                	sd	s0,0(sp)
    80000b22:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b24:	00007597          	auipc	a1,0x7
    80000b28:	54458593          	addi	a1,a1,1348 # 80008068 <digits+0x28>
    80000b2c:	00010517          	auipc	a0,0x10
    80000b30:	74450513          	addi	a0,a0,1860 # 80011270 <kmem>
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	084080e7          	jalr	132(ra) # 80000bb8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b3c:	45c5                	li	a1,17
    80000b3e:	05ee                	slli	a1,a1,0x1b
    80000b40:	00022517          	auipc	a0,0x22
    80000b44:	e0050513          	addi	a0,a0,-512 # 80022940 <end>
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	f88080e7          	jalr	-120(ra) # 80000ad0 <freerange>
}
    80000b50:	60a2                	ld	ra,8(sp)
    80000b52:	6402                	ld	s0,0(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b58:	1101                	addi	sp,sp,-32
    80000b5a:	ec06                	sd	ra,24(sp)
    80000b5c:	e822                	sd	s0,16(sp)
    80000b5e:	e426                	sd	s1,8(sp)
    80000b60:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b62:	00010497          	auipc	s1,0x10
    80000b66:	70e48493          	addi	s1,s1,1806 # 80011270 <kmem>
    80000b6a:	8526                	mv	a0,s1
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	0dc080e7          	jalr	220(ra) # 80000c48 <acquire>
  r = kmem.freelist;
    80000b74:	6c84                	ld	s1,24(s1)
  if(r)
    80000b76:	c885                	beqz	s1,80000ba6 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b78:	609c                	ld	a5,0(s1)
    80000b7a:	00010517          	auipc	a0,0x10
    80000b7e:	6f650513          	addi	a0,a0,1782 # 80011270 <kmem>
    80000b82:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	178080e7          	jalr	376(ra) # 80000cfc <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b8c:	6605                	lui	a2,0x1
    80000b8e:	4595                	li	a1,5
    80000b90:	8526                	mv	a0,s1
    80000b92:	00000097          	auipc	ra,0x0
    80000b96:	1b2080e7          	jalr	434(ra) # 80000d44 <memset>
  return (void*)r;
}
    80000b9a:	8526                	mv	a0,s1
    80000b9c:	60e2                	ld	ra,24(sp)
    80000b9e:	6442                	ld	s0,16(sp)
    80000ba0:	64a2                	ld	s1,8(sp)
    80000ba2:	6105                	addi	sp,sp,32
    80000ba4:	8082                	ret
  release(&kmem.lock);
    80000ba6:	00010517          	auipc	a0,0x10
    80000baa:	6ca50513          	addi	a0,a0,1738 # 80011270 <kmem>
    80000bae:	00000097          	auipc	ra,0x0
    80000bb2:	14e080e7          	jalr	334(ra) # 80000cfc <release>
  if(r)
    80000bb6:	b7d5                	j	80000b9a <kalloc+0x42>

0000000080000bb8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bb8:	1141                	addi	sp,sp,-16
    80000bba:	e422                	sd	s0,8(sp)
    80000bbc:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bbe:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bc0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bc4:	00053823          	sd	zero,16(a0)
}
    80000bc8:	6422                	ld	s0,8(sp)
    80000bca:	0141                	addi	sp,sp,16
    80000bcc:	8082                	ret

0000000080000bce <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bce:	411c                	lw	a5,0(a0)
    80000bd0:	e399                	bnez	a5,80000bd6 <holding+0x8>
    80000bd2:	4501                	li	a0,0
  return r;
}
    80000bd4:	8082                	ret
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000be0:	6904                	ld	s1,16(a0)
    80000be2:	00001097          	auipc	ra,0x1
    80000be6:	e26080e7          	jalr	-474(ra) # 80001a08 <mycpu>
    80000bea:	40a48533          	sub	a0,s1,a0
    80000bee:	00153513          	seqz	a0,a0
}
    80000bf2:	60e2                	ld	ra,24(sp)
    80000bf4:	6442                	ld	s0,16(sp)
    80000bf6:	64a2                	ld	s1,8(sp)
    80000bf8:	6105                	addi	sp,sp,32
    80000bfa:	8082                	ret

0000000080000bfc <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bfc:	1101                	addi	sp,sp,-32
    80000bfe:	ec06                	sd	ra,24(sp)
    80000c00:	e822                	sd	s0,16(sp)
    80000c02:	e426                	sd	s1,8(sp)
    80000c04:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c06:	100024f3          	csrr	s1,sstatus
    80000c0a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c0e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c10:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	df4080e7          	jalr	-524(ra) # 80001a08 <mycpu>
    80000c1c:	5d3c                	lw	a5,120(a0)
    80000c1e:	cf89                	beqz	a5,80000c38 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c20:	00001097          	auipc	ra,0x1
    80000c24:	de8080e7          	jalr	-536(ra) # 80001a08 <mycpu>
    80000c28:	5d3c                	lw	a5,120(a0)
    80000c2a:	2785                	addiw	a5,a5,1
    80000c2c:	dd3c                	sw	a5,120(a0)
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret
    mycpu()->intena = old;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dd0080e7          	jalr	-560(ra) # 80001a08 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c40:	8085                	srli	s1,s1,0x1
    80000c42:	8885                	andi	s1,s1,1
    80000c44:	dd64                	sw	s1,124(a0)
    80000c46:	bfe9                	j	80000c20 <push_off+0x24>

0000000080000c48 <acquire>:
{
    80000c48:	1101                	addi	sp,sp,-32
    80000c4a:	ec06                	sd	ra,24(sp)
    80000c4c:	e822                	sd	s0,16(sp)
    80000c4e:	e426                	sd	s1,8(sp)
    80000c50:	1000                	addi	s0,sp,32
    80000c52:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c54:	00000097          	auipc	ra,0x0
    80000c58:	fa8080e7          	jalr	-88(ra) # 80000bfc <push_off>
  if(holding(lk))
    80000c5c:	8526                	mv	a0,s1
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	f70080e7          	jalr	-144(ra) # 80000bce <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c66:	4705                	li	a4,1
  if(holding(lk))
    80000c68:	e115                	bnez	a0,80000c8c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c6a:	87ba                	mv	a5,a4
    80000c6c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c70:	2781                	sext.w	a5,a5
    80000c72:	ffe5                	bnez	a5,80000c6a <acquire+0x22>
  __sync_synchronize();
    80000c74:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c78:	00001097          	auipc	ra,0x1
    80000c7c:	d90080e7          	jalr	-624(ra) # 80001a08 <mycpu>
    80000c80:	e888                	sd	a0,16(s1)
}
    80000c82:	60e2                	ld	ra,24(sp)
    80000c84:	6442                	ld	s0,16(sp)
    80000c86:	64a2                	ld	s1,8(sp)
    80000c88:	6105                	addi	sp,sp,32
    80000c8a:	8082                	ret
    panic("acquire");
    80000c8c:	00007517          	auipc	a0,0x7
    80000c90:	3e450513          	addi	a0,a0,996 # 80008070 <digits+0x30>
    80000c94:	00000097          	auipc	ra,0x0
    80000c98:	8ac080e7          	jalr	-1876(ra) # 80000540 <panic>

0000000080000c9c <pop_off>:

void
pop_off(void)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ca4:	00001097          	auipc	ra,0x1
    80000ca8:	d64080e7          	jalr	-668(ra) # 80001a08 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cac:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cb0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cb2:	e78d                	bnez	a5,80000cdc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cb4:	5d3c                	lw	a5,120(a0)
    80000cb6:	02f05b63          	blez	a5,80000cec <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cba:	37fd                	addiw	a5,a5,-1
    80000cbc:	0007871b          	sext.w	a4,a5
    80000cc0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cc2:	eb09                	bnez	a4,80000cd4 <pop_off+0x38>
    80000cc4:	5d7c                	lw	a5,124(a0)
    80000cc6:	c799                	beqz	a5,80000cd4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ccc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cd0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cd4:	60a2                	ld	ra,8(sp)
    80000cd6:	6402                	ld	s0,0(sp)
    80000cd8:	0141                	addi	sp,sp,16
    80000cda:	8082                	ret
    panic("pop_off - interruptible");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39c50513          	addi	a0,a0,924 # 80008078 <digits+0x38>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	85c080e7          	jalr	-1956(ra) # 80000540 <panic>
    panic("pop_off");
    80000cec:	00007517          	auipc	a0,0x7
    80000cf0:	3a450513          	addi	a0,a0,932 # 80008090 <digits+0x50>
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	84c080e7          	jalr	-1972(ra) # 80000540 <panic>

0000000080000cfc <release>:
{
    80000cfc:	1101                	addi	sp,sp,-32
    80000cfe:	ec06                	sd	ra,24(sp)
    80000d00:	e822                	sd	s0,16(sp)
    80000d02:	e426                	sd	s1,8(sp)
    80000d04:	1000                	addi	s0,sp,32
    80000d06:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	ec6080e7          	jalr	-314(ra) # 80000bce <holding>
    80000d10:	c115                	beqz	a0,80000d34 <release+0x38>
  lk->cpu = 0;
    80000d12:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d16:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d1a:	0f50000f          	fence	iorw,ow
    80000d1e:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	f7a080e7          	jalr	-134(ra) # 80000c9c <pop_off>
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	addi	sp,sp,32
    80000d32:	8082                	ret
    panic("release");
    80000d34:	00007517          	auipc	a0,0x7
    80000d38:	36450513          	addi	a0,a0,868 # 80008098 <digits+0x58>
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	804080e7          	jalr	-2044(ra) # 80000540 <panic>

0000000080000d44 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d44:	1141                	addi	sp,sp,-16
    80000d46:	e422                	sd	s0,8(sp)
    80000d48:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d4a:	ca19                	beqz	a2,80000d60 <memset+0x1c>
    80000d4c:	87aa                	mv	a5,a0
    80000d4e:	1602                	slli	a2,a2,0x20
    80000d50:	9201                	srli	a2,a2,0x20
    80000d52:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d56:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d5a:	0785                	addi	a5,a5,1
    80000d5c:	fee79de3          	bne	a5,a4,80000d56 <memset+0x12>
  }
  return dst;
}
    80000d60:	6422                	ld	s0,8(sp)
    80000d62:	0141                	addi	sp,sp,16
    80000d64:	8082                	ret

0000000080000d66 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d66:	1141                	addi	sp,sp,-16
    80000d68:	e422                	sd	s0,8(sp)
    80000d6a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d6c:	ca05                	beqz	a2,80000d9c <memcmp+0x36>
    80000d6e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d72:	1682                	slli	a3,a3,0x20
    80000d74:	9281                	srli	a3,a3,0x20
    80000d76:	0685                	addi	a3,a3,1
    80000d78:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d7a:	00054783          	lbu	a5,0(a0)
    80000d7e:	0005c703          	lbu	a4,0(a1)
    80000d82:	00e79863          	bne	a5,a4,80000d92 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d8a:	fed518e3          	bne	a0,a3,80000d7a <memcmp+0x14>
  }

  return 0;
    80000d8e:	4501                	li	a0,0
    80000d90:	a019                	j	80000d96 <memcmp+0x30>
      return *s1 - *s2;
    80000d92:	40e7853b          	subw	a0,a5,a4
}
    80000d96:	6422                	ld	s0,8(sp)
    80000d98:	0141                	addi	sp,sp,16
    80000d9a:	8082                	ret
  return 0;
    80000d9c:	4501                	li	a0,0
    80000d9e:	bfe5                	j	80000d96 <memcmp+0x30>

0000000080000da0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e422                	sd	s0,8(sp)
    80000da4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000da6:	c205                	beqz	a2,80000dc6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000da8:	02a5e263          	bltu	a1,a0,80000dcc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dac:	1602                	slli	a2,a2,0x20
    80000dae:	9201                	srli	a2,a2,0x20
    80000db0:	00c587b3          	add	a5,a1,a2
{
    80000db4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000db6:	0585                	addi	a1,a1,1
    80000db8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc6c1>
    80000dba:	fff5c683          	lbu	a3,-1(a1)
    80000dbe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000dc2:	fef59ae3          	bne	a1,a5,80000db6 <memmove+0x16>

  return dst;
}
    80000dc6:	6422                	ld	s0,8(sp)
    80000dc8:	0141                	addi	sp,sp,16
    80000dca:	8082                	ret
  if(s < d && s + n > d){
    80000dcc:	02061693          	slli	a3,a2,0x20
    80000dd0:	9281                	srli	a3,a3,0x20
    80000dd2:	00d58733          	add	a4,a1,a3
    80000dd6:	fce57be3          	bgeu	a0,a4,80000dac <memmove+0xc>
    d += n;
    80000dda:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ddc:	fff6079b          	addiw	a5,a2,-1
    80000de0:	1782                	slli	a5,a5,0x20
    80000de2:	9381                	srli	a5,a5,0x20
    80000de4:	fff7c793          	not	a5,a5
    80000de8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dea:	177d                	addi	a4,a4,-1
    80000dec:	16fd                	addi	a3,a3,-1
    80000dee:	00074603          	lbu	a2,0(a4)
    80000df2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000df6:	fee79ae3          	bne	a5,a4,80000dea <memmove+0x4a>
    80000dfa:	b7f1                	j	80000dc6 <memmove+0x26>

0000000080000dfc <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dfc:	1141                	addi	sp,sp,-16
    80000dfe:	e406                	sd	ra,8(sp)
    80000e00:	e022                	sd	s0,0(sp)
    80000e02:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	f9c080e7          	jalr	-100(ra) # 80000da0 <memmove>
}
    80000e0c:	60a2                	ld	ra,8(sp)
    80000e0e:	6402                	ld	s0,0(sp)
    80000e10:	0141                	addi	sp,sp,16
    80000e12:	8082                	ret

0000000080000e14 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e14:	1141                	addi	sp,sp,-16
    80000e16:	e422                	sd	s0,8(sp)
    80000e18:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e1a:	ce11                	beqz	a2,80000e36 <strncmp+0x22>
    80000e1c:	00054783          	lbu	a5,0(a0)
    80000e20:	cf89                	beqz	a5,80000e3a <strncmp+0x26>
    80000e22:	0005c703          	lbu	a4,0(a1)
    80000e26:	00f71a63          	bne	a4,a5,80000e3a <strncmp+0x26>
    n--, p++, q++;
    80000e2a:	367d                	addiw	a2,a2,-1
    80000e2c:	0505                	addi	a0,a0,1
    80000e2e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e30:	f675                	bnez	a2,80000e1c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e32:	4501                	li	a0,0
    80000e34:	a809                	j	80000e46 <strncmp+0x32>
    80000e36:	4501                	li	a0,0
    80000e38:	a039                	j	80000e46 <strncmp+0x32>
  if(n == 0)
    80000e3a:	ca09                	beqz	a2,80000e4c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e3c:	00054503          	lbu	a0,0(a0)
    80000e40:	0005c783          	lbu	a5,0(a1)
    80000e44:	9d1d                	subw	a0,a0,a5
}
    80000e46:	6422                	ld	s0,8(sp)
    80000e48:	0141                	addi	sp,sp,16
    80000e4a:	8082                	ret
    return 0;
    80000e4c:	4501                	li	a0,0
    80000e4e:	bfe5                	j	80000e46 <strncmp+0x32>

0000000080000e50 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e50:	1141                	addi	sp,sp,-16
    80000e52:	e422                	sd	s0,8(sp)
    80000e54:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e56:	87aa                	mv	a5,a0
    80000e58:	86b2                	mv	a3,a2
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	00d05963          	blez	a3,80000e6e <strncpy+0x1e>
    80000e60:	0785                	addi	a5,a5,1
    80000e62:	0005c703          	lbu	a4,0(a1)
    80000e66:	fee78fa3          	sb	a4,-1(a5)
    80000e6a:	0585                	addi	a1,a1,1
    80000e6c:	f775                	bnez	a4,80000e58 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e6e:	873e                	mv	a4,a5
    80000e70:	9fb5                	addw	a5,a5,a3
    80000e72:	37fd                	addiw	a5,a5,-1
    80000e74:	00c05963          	blez	a2,80000e86 <strncpy+0x36>
    *s++ = 0;
    80000e78:	0705                	addi	a4,a4,1
    80000e7a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e7e:	40e786bb          	subw	a3,a5,a4
    80000e82:	fed04be3          	bgtz	a3,80000e78 <strncpy+0x28>
  return os;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret

0000000080000e8c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e8c:	1141                	addi	sp,sp,-16
    80000e8e:	e422                	sd	s0,8(sp)
    80000e90:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e92:	02c05363          	blez	a2,80000eb8 <safestrcpy+0x2c>
    80000e96:	fff6069b          	addiw	a3,a2,-1
    80000e9a:	1682                	slli	a3,a3,0x20
    80000e9c:	9281                	srli	a3,a3,0x20
    80000e9e:	96ae                	add	a3,a3,a1
    80000ea0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ea2:	00d58963          	beq	a1,a3,80000eb4 <safestrcpy+0x28>
    80000ea6:	0585                	addi	a1,a1,1
    80000ea8:	0785                	addi	a5,a5,1
    80000eaa:	fff5c703          	lbu	a4,-1(a1)
    80000eae:	fee78fa3          	sb	a4,-1(a5)
    80000eb2:	fb65                	bnez	a4,80000ea2 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eb4:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <strlen>:

int
strlen(const char *s)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	cf91                	beqz	a5,80000ee4 <strlen+0x26>
    80000eca:	0505                	addi	a0,a0,1
    80000ecc:	87aa                	mv	a5,a0
    80000ece:	86be                	mv	a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	ff65                	bnez	a4,80000ece <strlen+0x10>
    80000ed8:	40a6853b          	subw	a0,a3,a0
    80000edc:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ee4:	4501                	li	a0,0
    80000ee6:	bfe5                	j	80000ede <strlen+0x20>

0000000080000ee8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee8:	1141                	addi	sp,sp,-16
    80000eea:	e406                	sd	ra,8(sp)
    80000eec:	e022                	sd	s0,0(sp)
    80000eee:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	b08080e7          	jalr	-1272(ra) # 800019f8 <cpuid>
    trap_and_emulate_init();

    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef8:	00008717          	auipc	a4,0x8
    80000efc:	11070713          	addi	a4,a4,272 # 80009008 <started>
  if(cpuid() == 0){
    80000f00:	c139                	beqz	a0,80000f46 <main+0x5e>
    while(started == 0)
    80000f02:	431c                	lw	a5,0(a4)
    80000f04:	2781                	sext.w	a5,a5
    80000f06:	dff5                	beqz	a5,80000f02 <main+0x1a>
      ;
    __sync_synchronize();
    80000f08:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f0c:	00001097          	auipc	ra,0x1
    80000f10:	aec080e7          	jalr	-1300(ra) # 800019f8 <cpuid>
    80000f14:	85aa                	mv	a1,a0
    80000f16:	00007517          	auipc	a0,0x7
    80000f1a:	1a250513          	addi	a0,a0,418 # 800080b8 <digits+0x78>
    80000f1e:	fffff097          	auipc	ra,0xfffff
    80000f22:	66c080e7          	jalr	1644(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	0e0080e7          	jalr	224(ra) # 80001006 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	7c2080e7          	jalr	1986(ra) # 800026f0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f36:	00005097          	auipc	ra,0x5
    80000f3a:	dba080e7          	jalr	-582(ra) # 80005cf0 <plicinithart>
  }

  scheduler();        
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	00a080e7          	jalr	10(ra) # 80001f48 <scheduler>
    consoleinit();
    80000f46:	fffff097          	auipc	ra,0xfffff
    80000f4a:	50a080e7          	jalr	1290(ra) # 80000450 <consoleinit>
    printfinit();
    80000f4e:	00000097          	auipc	ra,0x0
    80000f52:	89a080e7          	jalr	-1894(ra) # 800007e8 <printfinit>
    printf("\n");
    80000f56:	00007517          	auipc	a0,0x7
    80000f5a:	17250513          	addi	a0,a0,370 # 800080c8 <digits+0x88>
    80000f5e:	fffff097          	auipc	ra,0xfffff
    80000f62:	62c080e7          	jalr	1580(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f66:	00007517          	auipc	a0,0x7
    80000f6a:	13a50513          	addi	a0,a0,314 # 800080a0 <digits+0x60>
    80000f6e:	fffff097          	auipc	ra,0xfffff
    80000f72:	61c080e7          	jalr	1564(ra) # 8000058a <printf>
    printf("\n");
    80000f76:	00007517          	auipc	a0,0x7
    80000f7a:	15250513          	addi	a0,a0,338 # 800080c8 <digits+0x88>
    80000f7e:	fffff097          	auipc	ra,0xfffff
    80000f82:	60c080e7          	jalr	1548(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	b96080e7          	jalr	-1130(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    80000f8e:	00000097          	auipc	ra,0x0
    80000f92:	32e080e7          	jalr	814(ra) # 800012bc <kvminit>
    kvminithart();   // turn on paging
    80000f96:	00000097          	auipc	ra,0x0
    80000f9a:	070080e7          	jalr	112(ra) # 80001006 <kvminithart>
    procinit();      // process table
    80000f9e:	00001097          	auipc	ra,0x1
    80000fa2:	9a6080e7          	jalr	-1626(ra) # 80001944 <procinit>
    trapinit();      // trap vectors
    80000fa6:	00001097          	auipc	ra,0x1
    80000faa:	722080e7          	jalr	1826(ra) # 800026c8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fae:	00001097          	auipc	ra,0x1
    80000fb2:	742080e7          	jalr	1858(ra) # 800026f0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb6:	00005097          	auipc	ra,0x5
    80000fba:	d24080e7          	jalr	-732(ra) # 80005cda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fbe:	00005097          	auipc	ra,0x5
    80000fc2:	d32080e7          	jalr	-718(ra) # 80005cf0 <plicinithart>
    binit();         // buffer cache
    80000fc6:	00002097          	auipc	ra,0x2
    80000fca:	eca080e7          	jalr	-310(ra) # 80002e90 <binit>
    iinit();         // inode table
    80000fce:	00002097          	auipc	ra,0x2
    80000fd2:	568080e7          	jalr	1384(ra) # 80003536 <iinit>
    fileinit();      // file table
    80000fd6:	00003097          	auipc	ra,0x3
    80000fda:	4de080e7          	jalr	1246(ra) # 800044b4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fde:	00005097          	auipc	ra,0x5
    80000fe2:	e1a080e7          	jalr	-486(ra) # 80005df8 <virtio_disk_init>
    userinit();      // first user process
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	d44080e7          	jalr	-700(ra) # 80001d2a <userinit>
    trap_and_emulate_init();
    80000fee:	00006097          	auipc	ra,0x6
    80000ff2:	a8e080e7          	jalr	-1394(ra) # 80006a7c <trap_and_emulate_init>
    __sync_synchronize();
    80000ff6:	0ff0000f          	fence
    started = 1;
    80000ffa:	4785                	li	a5,1
    80000ffc:	00008717          	auipc	a4,0x8
    80001000:	00f72623          	sw	a5,12(a4) # 80009008 <started>
    80001004:	bf2d                	j	80000f3e <main+0x56>

0000000080001006 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001006:	1141                	addi	sp,sp,-16
    80001008:	e422                	sd	s0,8(sp)
    8000100a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000100c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00008797          	auipc	a5,0x8
    80001014:	0007b783          	ld	a5,0(a5) # 80009010 <kernel_pagetable>
    80001018:	83b1                	srli	a5,a5,0xc
    8000101a:	577d                	li	a4,-1
    8000101c:	177e                	slli	a4,a4,0x3f
    8000101e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001020:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001024:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001028:	6422                	ld	s0,8(sp)
    8000102a:	0141                	addi	sp,sp,16
    8000102c:	8082                	ret

000000008000102e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000102e:	7139                	addi	sp,sp,-64
    80001030:	fc06                	sd	ra,56(sp)
    80001032:	f822                	sd	s0,48(sp)
    80001034:	f426                	sd	s1,40(sp)
    80001036:	f04a                	sd	s2,32(sp)
    80001038:	ec4e                	sd	s3,24(sp)
    8000103a:	e852                	sd	s4,16(sp)
    8000103c:	e456                	sd	s5,8(sp)
    8000103e:	e05a                	sd	s6,0(sp)
    80001040:	0080                	addi	s0,sp,64
    80001042:	84aa                	mv	s1,a0
    80001044:	89ae                	mv	s3,a1
    80001046:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001048:	57fd                	li	a5,-1
    8000104a:	83e9                	srli	a5,a5,0x1a
    8000104c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000104e:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001050:	04b7f263          	bgeu	a5,a1,80001094 <walk+0x66>
    panic("walk");
    80001054:	00007517          	auipc	a0,0x7
    80001058:	07c50513          	addi	a0,a0,124 # 800080d0 <digits+0x90>
    8000105c:	fffff097          	auipc	ra,0xfffff
    80001060:	4e4080e7          	jalr	1252(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001064:	060a8663          	beqz	s5,800010d0 <walk+0xa2>
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	af0080e7          	jalr	-1296(ra) # 80000b58 <kalloc>
    80001070:	84aa                	mv	s1,a0
    80001072:	c529                	beqz	a0,800010bc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001074:	6605                	lui	a2,0x1
    80001076:	4581                	li	a1,0
    80001078:	00000097          	auipc	ra,0x0
    8000107c:	ccc080e7          	jalr	-820(ra) # 80000d44 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001080:	00c4d793          	srli	a5,s1,0xc
    80001084:	07aa                	slli	a5,a5,0xa
    80001086:	0017e793          	ori	a5,a5,1
    8000108a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000108e:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc6b7>
    80001090:	036a0063          	beq	s4,s6,800010b0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001094:	0149d933          	srl	s2,s3,s4
    80001098:	1ff97913          	andi	s2,s2,511
    8000109c:	090e                	slli	s2,s2,0x3
    8000109e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a0:	00093483          	ld	s1,0(s2)
    800010a4:	0014f793          	andi	a5,s1,1
    800010a8:	dfd5                	beqz	a5,80001064 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010aa:	80a9                	srli	s1,s1,0xa
    800010ac:	04b2                	slli	s1,s1,0xc
    800010ae:	b7c5                	j	8000108e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b0:	00c9d513          	srli	a0,s3,0xc
    800010b4:	1ff57513          	andi	a0,a0,511
    800010b8:	050e                	slli	a0,a0,0x3
    800010ba:	9526                	add	a0,a0,s1
}
    800010bc:	70e2                	ld	ra,56(sp)
    800010be:	7442                	ld	s0,48(sp)
    800010c0:	74a2                	ld	s1,40(sp)
    800010c2:	7902                	ld	s2,32(sp)
    800010c4:	69e2                	ld	s3,24(sp)
    800010c6:	6a42                	ld	s4,16(sp)
    800010c8:	6aa2                	ld	s5,8(sp)
    800010ca:	6b02                	ld	s6,0(sp)
    800010cc:	6121                	addi	sp,sp,64
    800010ce:	8082                	ret
        return 0;
    800010d0:	4501                	li	a0,0
    800010d2:	b7ed                	j	800010bc <walk+0x8e>

00000000800010d4 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d4:	57fd                	li	a5,-1
    800010d6:	83e9                	srli	a5,a5,0x1a
    800010d8:	00b7f463          	bgeu	a5,a1,800010e0 <walkaddr+0xc>
    return 0;
    800010dc:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010de:	8082                	ret
{
    800010e0:	1141                	addi	sp,sp,-16
    800010e2:	e406                	sd	ra,8(sp)
    800010e4:	e022                	sd	s0,0(sp)
    800010e6:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010e8:	4601                	li	a2,0
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	f44080e7          	jalr	-188(ra) # 8000102e <walk>
  if(pte == 0)
    800010f2:	c105                	beqz	a0,80001112 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f4:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f6:	0117f693          	andi	a3,a5,17
    800010fa:	4745                	li	a4,17
    return 0;
    800010fc:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010fe:	00e68663          	beq	a3,a4,8000110a <walkaddr+0x36>
}
    80001102:	60a2                	ld	ra,8(sp)
    80001104:	6402                	ld	s0,0(sp)
    80001106:	0141                	addi	sp,sp,16
    80001108:	8082                	ret
  pa = PTE2PA(*pte);
    8000110a:	83a9                	srli	a5,a5,0xa
    8000110c:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001110:	bfcd                	j	80001102 <walkaddr+0x2e>
    return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7fd                	j	80001102 <walkaddr+0x2e>

0000000080001116 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001116:	715d                	addi	sp,sp,-80
    80001118:	e486                	sd	ra,72(sp)
    8000111a:	e0a2                	sd	s0,64(sp)
    8000111c:	fc26                	sd	s1,56(sp)
    8000111e:	f84a                	sd	s2,48(sp)
    80001120:	f44e                	sd	s3,40(sp)
    80001122:	f052                	sd	s4,32(sp)
    80001124:	ec56                	sd	s5,24(sp)
    80001126:	e85a                	sd	s6,16(sp)
    80001128:	e45e                	sd	s7,8(sp)
    8000112a:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000112c:	c639                	beqz	a2,8000117a <mappages+0x64>
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001132:	777d                	lui	a4,0xfffff
    80001134:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001138:	fff58993          	addi	s3,a1,-1
    8000113c:	99b2                	add	s3,s3,a2
    8000113e:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001142:	893e                	mv	s2,a5
    80001144:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001148:	6b85                	lui	s7,0x1
    8000114a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114e:	4605                	li	a2,1
    80001150:	85ca                	mv	a1,s2
    80001152:	8556                	mv	a0,s5
    80001154:	00000097          	auipc	ra,0x0
    80001158:	eda080e7          	jalr	-294(ra) # 8000102e <walk>
    8000115c:	cd1d                	beqz	a0,8000119a <mappages+0x84>
    if(*pte & PTE_V)
    8000115e:	611c                	ld	a5,0(a0)
    80001160:	8b85                	andi	a5,a5,1
    80001162:	e785                	bnez	a5,8000118a <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001164:	80b1                	srli	s1,s1,0xc
    80001166:	04aa                	slli	s1,s1,0xa
    80001168:	0164e4b3          	or	s1,s1,s6
    8000116c:	0014e493          	ori	s1,s1,1
    80001170:	e104                	sd	s1,0(a0)
    if(a == last)
    80001172:	05390063          	beq	s2,s3,800011b2 <mappages+0x9c>
    a += PGSIZE;
    80001176:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001178:	bfc9                	j	8000114a <mappages+0x34>
    panic("mappages: size");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f5e50513          	addi	a0,a0,-162 # 800080d8 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3be080e7          	jalr	958(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f5e50513          	addi	a0,a0,-162 # 800080e8 <digits+0xa8>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3ae080e7          	jalr	942(ra) # 80000540 <panic>
      return -1;
    8000119a:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000119c:	60a6                	ld	ra,72(sp)
    8000119e:	6406                	ld	s0,64(sp)
    800011a0:	74e2                	ld	s1,56(sp)
    800011a2:	7942                	ld	s2,48(sp)
    800011a4:	79a2                	ld	s3,40(sp)
    800011a6:	7a02                	ld	s4,32(sp)
    800011a8:	6ae2                	ld	s5,24(sp)
    800011aa:	6b42                	ld	s6,16(sp)
    800011ac:	6ba2                	ld	s7,8(sp)
    800011ae:	6161                	addi	sp,sp,80
    800011b0:	8082                	ret
  return 0;
    800011b2:	4501                	li	a0,0
    800011b4:	b7e5                	j	8000119c <mappages+0x86>

00000000800011b6 <kvmmap>:
{
    800011b6:	1141                	addi	sp,sp,-16
    800011b8:	e406                	sd	ra,8(sp)
    800011ba:	e022                	sd	s0,0(sp)
    800011bc:	0800                	addi	s0,sp,16
    800011be:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011c0:	86b2                	mv	a3,a2
    800011c2:	863e                	mv	a2,a5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	f52080e7          	jalr	-174(ra) # 80001116 <mappages>
    800011cc:	e509                	bnez	a0,800011d6 <kvmmap+0x20>
}
    800011ce:	60a2                	ld	ra,8(sp)
    800011d0:	6402                	ld	s0,0(sp)
    800011d2:	0141                	addi	sp,sp,16
    800011d4:	8082                	ret
    panic("kvmmap");
    800011d6:	00007517          	auipc	a0,0x7
    800011da:	f2250513          	addi	a0,a0,-222 # 800080f8 <digits+0xb8>
    800011de:	fffff097          	auipc	ra,0xfffff
    800011e2:	362080e7          	jalr	866(ra) # 80000540 <panic>

00000000800011e6 <kvmmake>:
{
    800011e6:	1101                	addi	sp,sp,-32
    800011e8:	ec06                	sd	ra,24(sp)
    800011ea:	e822                	sd	s0,16(sp)
    800011ec:	e426                	sd	s1,8(sp)
    800011ee:	e04a                	sd	s2,0(sp)
    800011f0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011f2:	00000097          	auipc	ra,0x0
    800011f6:	966080e7          	jalr	-1690(ra) # 80000b58 <kalloc>
    800011fa:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	b44080e7          	jalr	-1212(ra) # 80000d44 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	6685                	lui	a3,0x1
    8000120c:	10000637          	lui	a2,0x10000
    80001210:	100005b7          	lui	a1,0x10000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	fa0080e7          	jalr	-96(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000121e:	4719                	li	a4,6
    80001220:	6685                	lui	a3,0x1
    80001222:	10001637          	lui	a2,0x10001
    80001226:	100015b7          	lui	a1,0x10001
    8000122a:	8526                	mv	a0,s1
    8000122c:	00000097          	auipc	ra,0x0
    80001230:	f8a080e7          	jalr	-118(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001234:	4719                	li	a4,6
    80001236:	004006b7          	lui	a3,0x400
    8000123a:	0c000637          	lui	a2,0xc000
    8000123e:	0c0005b7          	lui	a1,0xc000
    80001242:	8526                	mv	a0,s1
    80001244:	00000097          	auipc	ra,0x0
    80001248:	f72080e7          	jalr	-142(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000124c:	00007917          	auipc	s2,0x7
    80001250:	db490913          	addi	s2,s2,-588 # 80008000 <etext>
    80001254:	4729                	li	a4,10
    80001256:	80007697          	auipc	a3,0x80007
    8000125a:	daa68693          	addi	a3,a3,-598 # 8000 <_entry-0x7fff8000>
    8000125e:	4605                	li	a2,1
    80001260:	067e                	slli	a2,a2,0x1f
    80001262:	85b2                	mv	a1,a2
    80001264:	8526                	mv	a0,s1
    80001266:	00000097          	auipc	ra,0x0
    8000126a:	f50080e7          	jalr	-176(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000126e:	4719                	li	a4,6
    80001270:	46c5                	li	a3,17
    80001272:	06ee                	slli	a3,a3,0x1b
    80001274:	412686b3          	sub	a3,a3,s2
    80001278:	864a                	mv	a2,s2
    8000127a:	85ca                	mv	a1,s2
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f38080e7          	jalr	-200(ra) # 800011b6 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001286:	4729                	li	a4,10
    80001288:	6685                	lui	a3,0x1
    8000128a:	00006617          	auipc	a2,0x6
    8000128e:	d7660613          	addi	a2,a2,-650 # 80007000 <_trampoline>
    80001292:	040005b7          	lui	a1,0x4000
    80001296:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001298:	05b2                	slli	a1,a1,0xc
    8000129a:	8526                	mv	a0,s1
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	f1a080e7          	jalr	-230(ra) # 800011b6 <kvmmap>
  proc_mapstacks(kpgtbl);
    800012a4:	8526                	mv	a0,s1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	608080e7          	jalr	1544(ra) # 800018ae <proc_mapstacks>
}
    800012ae:	8526                	mv	a0,s1
    800012b0:	60e2                	ld	ra,24(sp)
    800012b2:	6442                	ld	s0,16(sp)
    800012b4:	64a2                	ld	s1,8(sp)
    800012b6:	6902                	ld	s2,0(sp)
    800012b8:	6105                	addi	sp,sp,32
    800012ba:	8082                	ret

00000000800012bc <kvminit>:
{
    800012bc:	1141                	addi	sp,sp,-16
    800012be:	e406                	sd	ra,8(sp)
    800012c0:	e022                	sd	s0,0(sp)
    800012c2:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f22080e7          	jalr	-222(ra) # 800011e6 <kvmmake>
    800012cc:	00008797          	auipc	a5,0x8
    800012d0:	d4a7b223          	sd	a0,-700(a5) # 80009010 <kernel_pagetable>
}
    800012d4:	60a2                	ld	ra,8(sp)
    800012d6:	6402                	ld	s0,0(sp)
    800012d8:	0141                	addi	sp,sp,16
    800012da:	8082                	ret

00000000800012dc <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012dc:	715d                	addi	sp,sp,-80
    800012de:	e486                	sd	ra,72(sp)
    800012e0:	e0a2                	sd	s0,64(sp)
    800012e2:	fc26                	sd	s1,56(sp)
    800012e4:	f84a                	sd	s2,48(sp)
    800012e6:	f44e                	sd	s3,40(sp)
    800012e8:	f052                	sd	s4,32(sp)
    800012ea:	ec56                	sd	s5,24(sp)
    800012ec:	e85a                	sd	s6,16(sp)
    800012ee:	e45e                	sd	s7,8(sp)
    800012f0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012f2:	03459793          	slli	a5,a1,0x34
    800012f6:	e795                	bnez	a5,80001322 <uvmunmap+0x46>
    800012f8:	8a2a                	mv	s4,a0
    800012fa:	892e                	mv	s2,a1
    800012fc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012fe:	0632                	slli	a2,a2,0xc
    80001300:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001304:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001306:	6b05                	lui	s6,0x1
    80001308:	0735e263          	bltu	a1,s3,8000136c <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000130c:	60a6                	ld	ra,72(sp)
    8000130e:	6406                	ld	s0,64(sp)
    80001310:	74e2                	ld	s1,56(sp)
    80001312:	7942                	ld	s2,48(sp)
    80001314:	79a2                	ld	s3,40(sp)
    80001316:	7a02                	ld	s4,32(sp)
    80001318:	6ae2                	ld	s5,24(sp)
    8000131a:	6b42                	ld	s6,16(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
    8000131e:	6161                	addi	sp,sp,80
    80001320:	8082                	ret
    panic("uvmunmap: not aligned");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dde50513          	addi	a0,a0,-546 # 80008100 <digits+0xc0>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	216080e7          	jalr	534(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	de650513          	addi	a0,a0,-538 # 80008118 <digits+0xd8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	206080e7          	jalr	518(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001342:	00007517          	auipc	a0,0x7
    80001346:	de650513          	addi	a0,a0,-538 # 80008128 <digits+0xe8>
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	1f6080e7          	jalr	502(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001352:	00007517          	auipc	a0,0x7
    80001356:	dee50513          	addi	a0,a0,-530 # 80008140 <digits+0x100>
    8000135a:	fffff097          	auipc	ra,0xfffff
    8000135e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    *pte = 0;
    80001362:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001366:	995a                	add	s2,s2,s6
    80001368:	fb3972e3          	bgeu	s2,s3,8000130c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000136c:	4601                	li	a2,0
    8000136e:	85ca                	mv	a1,s2
    80001370:	8552                	mv	a0,s4
    80001372:	00000097          	auipc	ra,0x0
    80001376:	cbc080e7          	jalr	-836(ra) # 8000102e <walk>
    8000137a:	84aa                	mv	s1,a0
    8000137c:	d95d                	beqz	a0,80001332 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000137e:	6108                	ld	a0,0(a0)
    80001380:	00157793          	andi	a5,a0,1
    80001384:	dfdd                	beqz	a5,80001342 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001386:	3ff57793          	andi	a5,a0,1023
    8000138a:	fd7784e3          	beq	a5,s7,80001352 <uvmunmap+0x76>
    if(do_free){
    8000138e:	fc0a8ae3          	beqz	s5,80001362 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001392:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001394:	0532                	slli	a0,a0,0xc
    80001396:	fffff097          	auipc	ra,0xfffff
    8000139a:	6c4080e7          	jalr	1732(ra) # 80000a5a <kfree>
    8000139e:	b7d1                	j	80001362 <uvmunmap+0x86>

00000000800013a0 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013a0:	1101                	addi	sp,sp,-32
    800013a2:	ec06                	sd	ra,24(sp)
    800013a4:	e822                	sd	s0,16(sp)
    800013a6:	e426                	sd	s1,8(sp)
    800013a8:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013aa:	fffff097          	auipc	ra,0xfffff
    800013ae:	7ae080e7          	jalr	1966(ra) # 80000b58 <kalloc>
    800013b2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013b4:	c519                	beqz	a0,800013c2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b6:	6605                	lui	a2,0x1
    800013b8:	4581                	li	a1,0
    800013ba:	00000097          	auipc	ra,0x0
    800013be:	98a080e7          	jalr	-1654(ra) # 80000d44 <memset>
  return pagetable;
}
    800013c2:	8526                	mv	a0,s1
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	addi	sp,sp,32
    800013cc:	8082                	ret

00000000800013ce <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ce:	7179                	addi	sp,sp,-48
    800013d0:	f406                	sd	ra,40(sp)
    800013d2:	f022                	sd	s0,32(sp)
    800013d4:	ec26                	sd	s1,24(sp)
    800013d6:	e84a                	sd	s2,16(sp)
    800013d8:	e44e                	sd	s3,8(sp)
    800013da:	e052                	sd	s4,0(sp)
    800013dc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013de:	6785                	lui	a5,0x1
    800013e0:	04f67863          	bgeu	a2,a5,80001430 <uvmfirst+0x62>
    800013e4:	8a2a                	mv	s4,a0
    800013e6:	89ae                	mv	s3,a1
    800013e8:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	76e080e7          	jalr	1902(ra) # 80000b58 <kalloc>
    800013f2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013f4:	6605                	lui	a2,0x1
    800013f6:	4581                	li	a1,0
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	94c080e7          	jalr	-1716(ra) # 80000d44 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001400:	4779                	li	a4,30
    80001402:	86ca                	mv	a3,s2
    80001404:	6605                	lui	a2,0x1
    80001406:	4581                	li	a1,0
    80001408:	8552                	mv	a0,s4
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	d0c080e7          	jalr	-756(ra) # 80001116 <mappages>
  memmove(mem, src, sz);
    80001412:	8626                	mv	a2,s1
    80001414:	85ce                	mv	a1,s3
    80001416:	854a                	mv	a0,s2
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	988080e7          	jalr	-1656(ra) # 80000da0 <memmove>
}
    80001420:	70a2                	ld	ra,40(sp)
    80001422:	7402                	ld	s0,32(sp)
    80001424:	64e2                	ld	s1,24(sp)
    80001426:	6942                	ld	s2,16(sp)
    80001428:	69a2                	ld	s3,8(sp)
    8000142a:	6a02                	ld	s4,0(sp)
    8000142c:	6145                	addi	sp,sp,48
    8000142e:	8082                	ret
    panic("uvmfirst: more than a page");
    80001430:	00007517          	auipc	a0,0x7
    80001434:	d2850513          	addi	a0,a0,-728 # 80008158 <digits+0x118>
    80001438:	fffff097          	auipc	ra,0xfffff
    8000143c:	108080e7          	jalr	264(ra) # 80000540 <panic>

0000000080001440 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001440:	1101                	addi	sp,sp,-32
    80001442:	ec06                	sd	ra,24(sp)
    80001444:	e822                	sd	s0,16(sp)
    80001446:	e426                	sd	s1,8(sp)
    80001448:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000144a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000144c:	00b67d63          	bgeu	a2,a1,80001466 <uvmdealloc+0x26>
    80001450:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001452:	6785                	lui	a5,0x1
    80001454:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001456:	00f60733          	add	a4,a2,a5
    8000145a:	76fd                	lui	a3,0xfffff
    8000145c:	8f75                	and	a4,a4,a3
    8000145e:	97ae                	add	a5,a5,a1
    80001460:	8ff5                	and	a5,a5,a3
    80001462:	00f76863          	bltu	a4,a5,80001472 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001466:	8526                	mv	a0,s1
    80001468:	60e2                	ld	ra,24(sp)
    8000146a:	6442                	ld	s0,16(sp)
    8000146c:	64a2                	ld	s1,8(sp)
    8000146e:	6105                	addi	sp,sp,32
    80001470:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001472:	8f99                	sub	a5,a5,a4
    80001474:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001476:	4685                	li	a3,1
    80001478:	0007861b          	sext.w	a2,a5
    8000147c:	85ba                	mv	a1,a4
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	e5e080e7          	jalr	-418(ra) # 800012dc <uvmunmap>
    80001486:	b7c5                	j	80001466 <uvmdealloc+0x26>

0000000080001488 <uvmalloc>:
  if(newsz < oldsz)
    80001488:	0ab66563          	bltu	a2,a1,80001532 <uvmalloc+0xaa>
{
    8000148c:	7139                	addi	sp,sp,-64
    8000148e:	fc06                	sd	ra,56(sp)
    80001490:	f822                	sd	s0,48(sp)
    80001492:	f426                	sd	s1,40(sp)
    80001494:	f04a                	sd	s2,32(sp)
    80001496:	ec4e                	sd	s3,24(sp)
    80001498:	e852                	sd	s4,16(sp)
    8000149a:	e456                	sd	s5,8(sp)
    8000149c:	e05a                	sd	s6,0(sp)
    8000149e:	0080                	addi	s0,sp,64
    800014a0:	8aaa                	mv	s5,a0
    800014a2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014a4:	6785                	lui	a5,0x1
    800014a6:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800014a8:	95be                	add	a1,a1,a5
    800014aa:	77fd                	lui	a5,0xfffff
    800014ac:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b0:	08c9f363          	bgeu	s3,a2,80001536 <uvmalloc+0xae>
    800014b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ba:	fffff097          	auipc	ra,0xfffff
    800014be:	69e080e7          	jalr	1694(ra) # 80000b58 <kalloc>
    800014c2:	84aa                	mv	s1,a0
    if(mem == 0){
    800014c4:	c51d                	beqz	a0,800014f2 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800014c6:	6605                	lui	a2,0x1
    800014c8:	4581                	li	a1,0
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	87a080e7          	jalr	-1926(ra) # 80000d44 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014d2:	875a                	mv	a4,s6
    800014d4:	86a6                	mv	a3,s1
    800014d6:	6605                	lui	a2,0x1
    800014d8:	85ca                	mv	a1,s2
    800014da:	8556                	mv	a0,s5
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	c3a080e7          	jalr	-966(ra) # 80001116 <mappages>
    800014e4:	e90d                	bnez	a0,80001516 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014e6:	6785                	lui	a5,0x1
    800014e8:	993e                	add	s2,s2,a5
    800014ea:	fd4968e3          	bltu	s2,s4,800014ba <uvmalloc+0x32>
  return newsz;
    800014ee:	8552                	mv	a0,s4
    800014f0:	a809                	j	80001502 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f48080e7          	jalr	-184(ra) # 80001440 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
}
    80001502:	70e2                	ld	ra,56(sp)
    80001504:	7442                	ld	s0,48(sp)
    80001506:	74a2                	ld	s1,40(sp)
    80001508:	7902                	ld	s2,32(sp)
    8000150a:	69e2                	ld	s3,24(sp)
    8000150c:	6a42                	ld	s4,16(sp)
    8000150e:	6aa2                	ld	s5,8(sp)
    80001510:	6b02                	ld	s6,0(sp)
    80001512:	6121                	addi	sp,sp,64
    80001514:	8082                	ret
      kfree(mem);
    80001516:	8526                	mv	a0,s1
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	542080e7          	jalr	1346(ra) # 80000a5a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001520:	864e                	mv	a2,s3
    80001522:	85ca                	mv	a1,s2
    80001524:	8556                	mv	a0,s5
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	f1a080e7          	jalr	-230(ra) # 80001440 <uvmdealloc>
      return 0;
    8000152e:	4501                	li	a0,0
    80001530:	bfc9                	j	80001502 <uvmalloc+0x7a>
    return oldsz;
    80001532:	852e                	mv	a0,a1
}
    80001534:	8082                	ret
  return newsz;
    80001536:	8532                	mv	a0,a2
    80001538:	b7e9                	j	80001502 <uvmalloc+0x7a>

000000008000153a <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153a:	7179                	addi	sp,sp,-48
    8000153c:	f406                	sd	ra,40(sp)
    8000153e:	f022                	sd	s0,32(sp)
    80001540:	ec26                	sd	s1,24(sp)
    80001542:	e84a                	sd	s2,16(sp)
    80001544:	e44e                	sd	s3,8(sp)
    80001546:	e052                	sd	s4,0(sp)
    80001548:	1800                	addi	s0,sp,48
    8000154a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154c:	84aa                	mv	s1,a0
    8000154e:	6905                	lui	s2,0x1
    80001550:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001552:	4985                	li	s3,1
    80001554:	a829                	j	8000156e <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001556:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001558:	00c79513          	slli	a0,a5,0xc
    8000155c:	00000097          	auipc	ra,0x0
    80001560:	fde080e7          	jalr	-34(ra) # 8000153a <freewalk>
      pagetable[i] = 0;
    80001564:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001568:	04a1                	addi	s1,s1,8
    8000156a:	03248163          	beq	s1,s2,8000158c <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001570:	00f7f713          	andi	a4,a5,15
    80001574:	ff3701e3          	beq	a4,s3,80001556 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001578:	8b85                	andi	a5,a5,1
    8000157a:	d7fd                	beqz	a5,80001568 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157c:	00007517          	auipc	a0,0x7
    80001580:	bfc50513          	addi	a0,a0,-1028 # 80008178 <digits+0x138>
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	fbc080e7          	jalr	-68(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158c:	8552                	mv	a0,s4
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	4cc080e7          	jalr	1228(ra) # 80000a5a <kfree>
}
    80001596:	70a2                	ld	ra,40(sp)
    80001598:	7402                	ld	s0,32(sp)
    8000159a:	64e2                	ld	s1,24(sp)
    8000159c:	6942                	ld	s2,16(sp)
    8000159e:	69a2                	ld	s3,8(sp)
    800015a0:	6a02                	ld	s4,0(sp)
    800015a2:	6145                	addi	sp,sp,48
    800015a4:	8082                	ret

00000000800015a6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a6:	1101                	addi	sp,sp,-32
    800015a8:	ec06                	sd	ra,24(sp)
    800015aa:	e822                	sd	s0,16(sp)
    800015ac:	e426                	sd	s1,8(sp)
    800015ae:	1000                	addi	s0,sp,32
    800015b0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b2:	e999                	bnez	a1,800015c8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b4:	8526                	mv	a0,s1
    800015b6:	00000097          	auipc	ra,0x0
    800015ba:	f84080e7          	jalr	-124(ra) # 8000153a <freewalk>
}
    800015be:	60e2                	ld	ra,24(sp)
    800015c0:	6442                	ld	s0,16(sp)
    800015c2:	64a2                	ld	s1,8(sp)
    800015c4:	6105                	addi	sp,sp,32
    800015c6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c8:	6785                	lui	a5,0x1
    800015ca:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015cc:	95be                	add	a1,a1,a5
    800015ce:	4685                	li	a3,1
    800015d0:	00c5d613          	srli	a2,a1,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d06080e7          	jalr	-762(ra) # 800012dc <uvmunmap>
    800015de:	bfd9                	j	800015b4 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	a28080e7          	jalr	-1496(ra) # 8000102e <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	534080e7          	jalr	1332(ra) # 80000b58 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	76c080e7          	jalr	1900(ra) # 80000da0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	ad0080e7          	jalr	-1328(ra) # 80001116 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00007517          	auipc	a0,0x7
    8000165e:	b2e50513          	addi	a0,a0,-1234 # 80008188 <digits+0x148>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ede080e7          	jalr	-290(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b3e50513          	addi	a0,a0,-1218 # 800081a8 <digits+0x168>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3de080e7          	jalr	990(ra) # 80000a5a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c4e080e7          	jalr	-946(ra) # 800012dc <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	972080e7          	jalr	-1678(ra) # 8000102e <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	af450513          	addi	a0,a0,-1292 # 800081c8 <digits+0x188>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	688080e7          	jalr	1672(ra) # 80000da0 <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	99e080e7          	jalr	-1634(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001770:	caa5                	beqz	a3,800017e0 <copyin+0x70>
{
    80001772:	715d                	addi	sp,sp,-80
    80001774:	e486                	sd	ra,72(sp)
    80001776:	e0a2                	sd	s0,64(sp)
    80001778:	fc26                	sd	s1,56(sp)
    8000177a:	f84a                	sd	s2,48(sp)
    8000177c:	f44e                	sd	s3,40(sp)
    8000177e:	f052                	sd	s4,32(sp)
    80001780:	ec56                	sd	s5,24(sp)
    80001782:	e85a                	sd	s6,16(sp)
    80001784:	e45e                	sd	s7,8(sp)
    80001786:	e062                	sd	s8,0(sp)
    80001788:	0880                	addi	s0,sp,80
    8000178a:	8b2a                	mv	s6,a0
    8000178c:	8a2e                	mv	s4,a1
    8000178e:	8c32                	mv	s8,a2
    80001790:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001792:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001794:	6a85                	lui	s5,0x1
    80001796:	a01d                	j	800017bc <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001798:	018505b3          	add	a1,a0,s8
    8000179c:	0004861b          	sext.w	a2,s1
    800017a0:	412585b3          	sub	a1,a1,s2
    800017a4:	8552                	mv	a0,s4
    800017a6:	fffff097          	auipc	ra,0xfffff
    800017aa:	5fa080e7          	jalr	1530(ra) # 80000da0 <memmove>

    len -= n;
    800017ae:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b8:	02098263          	beqz	s3,800017dc <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017c0:	85ca                	mv	a1,s2
    800017c2:	855a                	mv	a0,s6
    800017c4:	00000097          	auipc	ra,0x0
    800017c8:	910080e7          	jalr	-1776(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    800017cc:	cd01                	beqz	a0,800017e4 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017ce:	418904b3          	sub	s1,s2,s8
    800017d2:	94d6                	add	s1,s1,s5
    800017d4:	fc99f2e3          	bgeu	s3,s1,80001798 <copyin+0x28>
    800017d8:	84ce                	mv	s1,s3
    800017da:	bf7d                	j	80001798 <copyin+0x28>
  }
  return 0;
    800017dc:	4501                	li	a0,0
    800017de:	a021                	j	800017e6 <copyin+0x76>
    800017e0:	4501                	li	a0,0
}
    800017e2:	8082                	ret
      return -1;
    800017e4:	557d                	li	a0,-1
}
    800017e6:	60a6                	ld	ra,72(sp)
    800017e8:	6406                	ld	s0,64(sp)
    800017ea:	74e2                	ld	s1,56(sp)
    800017ec:	7942                	ld	s2,48(sp)
    800017ee:	79a2                	ld	s3,40(sp)
    800017f0:	7a02                	ld	s4,32(sp)
    800017f2:	6ae2                	ld	s5,24(sp)
    800017f4:	6b42                	ld	s6,16(sp)
    800017f6:	6ba2                	ld	s7,8(sp)
    800017f8:	6c02                	ld	s8,0(sp)
    800017fa:	6161                	addi	sp,sp,80
    800017fc:	8082                	ret

00000000800017fe <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fe:	c2dd                	beqz	a3,800018a4 <copyinstr+0xa6>
{
    80001800:	715d                	addi	sp,sp,-80
    80001802:	e486                	sd	ra,72(sp)
    80001804:	e0a2                	sd	s0,64(sp)
    80001806:	fc26                	sd	s1,56(sp)
    80001808:	f84a                	sd	s2,48(sp)
    8000180a:	f44e                	sd	s3,40(sp)
    8000180c:	f052                	sd	s4,32(sp)
    8000180e:	ec56                	sd	s5,24(sp)
    80001810:	e85a                	sd	s6,16(sp)
    80001812:	e45e                	sd	s7,8(sp)
    80001814:	0880                	addi	s0,sp,80
    80001816:	8a2a                	mv	s4,a0
    80001818:	8b2e                	mv	s6,a1
    8000181a:	8bb2                	mv	s7,a2
    8000181c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000181e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001820:	6985                	lui	s3,0x1
    80001822:	a02d                	j	8000184c <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001824:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001828:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000182a:	37fd                	addiw	a5,a5,-1
    8000182c:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001830:	60a6                	ld	ra,72(sp)
    80001832:	6406                	ld	s0,64(sp)
    80001834:	74e2                	ld	s1,56(sp)
    80001836:	7942                	ld	s2,48(sp)
    80001838:	79a2                	ld	s3,40(sp)
    8000183a:	7a02                	ld	s4,32(sp)
    8000183c:	6ae2                	ld	s5,24(sp)
    8000183e:	6b42                	ld	s6,16(sp)
    80001840:	6ba2                	ld	s7,8(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret
    srcva = va0 + PGSIZE;
    80001846:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000184a:	c8a9                	beqz	s1,8000189c <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000184c:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001850:	85ca                	mv	a1,s2
    80001852:	8552                	mv	a0,s4
    80001854:	00000097          	auipc	ra,0x0
    80001858:	880080e7          	jalr	-1920(ra) # 800010d4 <walkaddr>
    if(pa0 == 0)
    8000185c:	c131                	beqz	a0,800018a0 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    8000185e:	417906b3          	sub	a3,s2,s7
    80001862:	96ce                	add	a3,a3,s3
    80001864:	00d4f363          	bgeu	s1,a3,8000186a <copyinstr+0x6c>
    80001868:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000186a:	955e                	add	a0,a0,s7
    8000186c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001870:	daf9                	beqz	a3,80001846 <copyinstr+0x48>
    80001872:	87da                	mv	a5,s6
    80001874:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001876:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000187a:	96da                	add	a3,a3,s6
    8000187c:	85be                	mv	a1,a5
      if(*p == '\0'){
    8000187e:	00f60733          	add	a4,a2,a5
    80001882:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc6c0>
    80001886:	df59                	beqz	a4,80001824 <copyinstr+0x26>
        *dst = *p;
    80001888:	00e78023          	sb	a4,0(a5)
      dst++;
    8000188c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000188e:	fed797e3          	bne	a5,a3,8000187c <copyinstr+0x7e>
    80001892:	14fd                	addi	s1,s1,-1
    80001894:	94c2                	add	s1,s1,a6
      --max;
    80001896:	8c8d                	sub	s1,s1,a1
      dst++;
    80001898:	8b3e                	mv	s6,a5
    8000189a:	b775                	j	80001846 <copyinstr+0x48>
    8000189c:	4781                	li	a5,0
    8000189e:	b771                	j	8000182a <copyinstr+0x2c>
      return -1;
    800018a0:	557d                	li	a0,-1
    800018a2:	b779                	j	80001830 <copyinstr+0x32>
  int got_null = 0;
    800018a4:	4781                	li	a5,0
  if(got_null){
    800018a6:	37fd                	addiw	a5,a5,-1
    800018a8:	0007851b          	sext.w	a0,a5
}
    800018ac:	8082                	ret

00000000800018ae <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    800018ae:	7139                	addi	sp,sp,-64
    800018b0:	fc06                	sd	ra,56(sp)
    800018b2:	f822                	sd	s0,48(sp)
    800018b4:	f426                	sd	s1,40(sp)
    800018b6:	f04a                	sd	s2,32(sp)
    800018b8:	ec4e                	sd	s3,24(sp)
    800018ba:	e852                	sd	s4,16(sp)
    800018bc:	e456                	sd	s5,8(sp)
    800018be:	e05a                	sd	s6,0(sp)
    800018c0:	0080                	addi	s0,sp,64
    800018c2:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800018c4:	00010497          	auipc	s1,0x10
    800018c8:	dfc48493          	addi	s1,s1,-516 # 800116c0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800018cc:	8b26                	mv	s6,s1
    800018ce:	00006a97          	auipc	s5,0x6
    800018d2:	732a8a93          	addi	s5,s5,1842 # 80008000 <etext>
    800018d6:	04000937          	lui	s2,0x4000
    800018da:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018dc:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018de:	00016a17          	auipc	s4,0x16
    800018e2:	9e2a0a13          	addi	s4,s4,-1566 # 800172c0 <tickslock>
    char *pa = kalloc();
    800018e6:	fffff097          	auipc	ra,0xfffff
    800018ea:	272080e7          	jalr	626(ra) # 80000b58 <kalloc>
    800018ee:	862a                	mv	a2,a0
    if(pa == 0)
    800018f0:	c131                	beqz	a0,80001934 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018f2:	416485b3          	sub	a1,s1,s6
    800018f6:	8591                	srai	a1,a1,0x4
    800018f8:	000ab783          	ld	a5,0(s5)
    800018fc:	02f585b3          	mul	a1,a1,a5
    80001900:	2585                	addiw	a1,a1,1
    80001902:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001906:	4719                	li	a4,6
    80001908:	6685                	lui	a3,0x1
    8000190a:	40b905b3          	sub	a1,s2,a1
    8000190e:	854e                	mv	a0,s3
    80001910:	00000097          	auipc	ra,0x0
    80001914:	8a6080e7          	jalr	-1882(ra) # 800011b6 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001918:	17048493          	addi	s1,s1,368
    8000191c:	fd4495e3          	bne	s1,s4,800018e6 <proc_mapstacks+0x38>
  }
}
    80001920:	70e2                	ld	ra,56(sp)
    80001922:	7442                	ld	s0,48(sp)
    80001924:	74a2                	ld	s1,40(sp)
    80001926:	7902                	ld	s2,32(sp)
    80001928:	69e2                	ld	s3,24(sp)
    8000192a:	6a42                	ld	s4,16(sp)
    8000192c:	6aa2                	ld	s5,8(sp)
    8000192e:	6b02                	ld	s6,0(sp)
    80001930:	6121                	addi	sp,sp,64
    80001932:	8082                	ret
      panic("kalloc");
    80001934:	00007517          	auipc	a0,0x7
    80001938:	8a450513          	addi	a0,a0,-1884 # 800081d8 <digits+0x198>
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	c04080e7          	jalr	-1020(ra) # 80000540 <panic>

0000000080001944 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001944:	7139                	addi	sp,sp,-64
    80001946:	fc06                	sd	ra,56(sp)
    80001948:	f822                	sd	s0,48(sp)
    8000194a:	f426                	sd	s1,40(sp)
    8000194c:	f04a                	sd	s2,32(sp)
    8000194e:	ec4e                	sd	s3,24(sp)
    80001950:	e852                	sd	s4,16(sp)
    80001952:	e456                	sd	s5,8(sp)
    80001954:	e05a                	sd	s6,0(sp)
    80001956:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001958:	00007597          	auipc	a1,0x7
    8000195c:	88858593          	addi	a1,a1,-1912 # 800081e0 <digits+0x1a0>
    80001960:	00010517          	auipc	a0,0x10
    80001964:	93050513          	addi	a0,a0,-1744 # 80011290 <pid_lock>
    80001968:	fffff097          	auipc	ra,0xfffff
    8000196c:	250080e7          	jalr	592(ra) # 80000bb8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001970:	00007597          	auipc	a1,0x7
    80001974:	87858593          	addi	a1,a1,-1928 # 800081e8 <digits+0x1a8>
    80001978:	00010517          	auipc	a0,0x10
    8000197c:	93050513          	addi	a0,a0,-1744 # 800112a8 <wait_lock>
    80001980:	fffff097          	auipc	ra,0xfffff
    80001984:	238080e7          	jalr	568(ra) # 80000bb8 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001988:	00010497          	auipc	s1,0x10
    8000198c:	d3848493          	addi	s1,s1,-712 # 800116c0 <proc>
      initlock(&p->lock, "proc");
    80001990:	00007b17          	auipc	s6,0x7
    80001994:	868b0b13          	addi	s6,s6,-1944 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001998:	8aa6                	mv	s5,s1
    8000199a:	00006a17          	auipc	s4,0x6
    8000199e:	666a0a13          	addi	s4,s4,1638 # 80008000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019a8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	00016997          	auipc	s3,0x16
    800019ae:	91698993          	addi	s3,s3,-1770 # 800172c0 <tickslock>
      initlock(&p->lock, "proc");
    800019b2:	85da                	mv	a1,s6
    800019b4:	8526                	mv	a0,s1
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	202080e7          	jalr	514(ra) # 80000bb8 <initlock>
      p->state = UNUSED;
    800019be:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800019c2:	415487b3          	sub	a5,s1,s5
    800019c6:	8791                	srai	a5,a5,0x4
    800019c8:	000a3703          	ld	a4,0(s4)
    800019cc:	02e787b3          	mul	a5,a5,a4
    800019d0:	2785                	addiw	a5,a5,1
    800019d2:	00d7979b          	slliw	a5,a5,0xd
    800019d6:	40f907b3          	sub	a5,s2,a5
    800019da:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019dc:	17048493          	addi	s1,s1,368
    800019e0:	fd3499e3          	bne	s1,s3,800019b2 <procinit+0x6e>
  }
}
    800019e4:	70e2                	ld	ra,56(sp)
    800019e6:	7442                	ld	s0,48(sp)
    800019e8:	74a2                	ld	s1,40(sp)
    800019ea:	7902                	ld	s2,32(sp)
    800019ec:	69e2                	ld	s3,24(sp)
    800019ee:	6a42                	ld	s4,16(sp)
    800019f0:	6aa2                	ld	s5,8(sp)
    800019f2:	6b02                	ld	s6,0(sp)
    800019f4:	6121                	addi	sp,sp,64
    800019f6:	8082                	ret

00000000800019f8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e422                	sd	s0,8(sp)
    800019fc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019fe:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a00:	2501                	sext.w	a0,a0
    80001a02:	6422                	ld	s0,8(sp)
    80001a04:	0141                	addi	sp,sp,16
    80001a06:	8082                	ret

0000000080001a08 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001a08:	1141                	addi	sp,sp,-16
    80001a0a:	e422                	sd	s0,8(sp)
    80001a0c:	0800                	addi	s0,sp,16
    80001a0e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a10:	2781                	sext.w	a5,a5
    80001a12:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a14:	00010517          	auipc	a0,0x10
    80001a18:	8ac50513          	addi	a0,a0,-1876 # 800112c0 <cpus>
    80001a1c:	953e                	add	a0,a0,a5
    80001a1e:	6422                	ld	s0,8(sp)
    80001a20:	0141                	addi	sp,sp,16
    80001a22:	8082                	ret

0000000080001a24 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    80001a24:	1101                	addi	sp,sp,-32
    80001a26:	ec06                	sd	ra,24(sp)
    80001a28:	e822                	sd	s0,16(sp)
    80001a2a:	e426                	sd	s1,8(sp)
    80001a2c:	1000                	addi	s0,sp,32
  push_off();
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	1ce080e7          	jalr	462(ra) # 80000bfc <push_off>
    80001a36:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a38:	2781                	sext.w	a5,a5
    80001a3a:	079e                	slli	a5,a5,0x7
    80001a3c:	00010717          	auipc	a4,0x10
    80001a40:	85470713          	addi	a4,a4,-1964 # 80011290 <pid_lock>
    80001a44:	97ba                	add	a5,a5,a4
    80001a46:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	254080e7          	jalr	596(ra) # 80000c9c <pop_off>
  return p;
}
    80001a50:	8526                	mv	a0,s1
    80001a52:	60e2                	ld	ra,24(sp)
    80001a54:	6442                	ld	s0,16(sp)
    80001a56:	64a2                	ld	s1,8(sp)
    80001a58:	6105                	addi	sp,sp,32
    80001a5a:	8082                	ret

0000000080001a5c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a5c:	1141                	addi	sp,sp,-16
    80001a5e:	e406                	sd	ra,8(sp)
    80001a60:	e022                	sd	s0,0(sp)
    80001a62:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a64:	00000097          	auipc	ra,0x0
    80001a68:	fc0080e7          	jalr	-64(ra) # 80001a24 <myproc>
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	290080e7          	jalr	656(ra) # 80000cfc <release>

  if (first) {
    80001a74:	00007797          	auipc	a5,0x7
    80001a78:	52c7a783          	lw	a5,1324(a5) # 80008fa0 <first.1>
    80001a7c:	eb89                	bnez	a5,80001a8e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a7e:	00001097          	auipc	ra,0x1
    80001a82:	c8a080e7          	jalr	-886(ra) # 80002708 <usertrapret>
}
    80001a86:	60a2                	ld	ra,8(sp)
    80001a88:	6402                	ld	s0,0(sp)
    80001a8a:	0141                	addi	sp,sp,16
    80001a8c:	8082                	ret
    first = 0;
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	5007a923          	sw	zero,1298(a5) # 80008fa0 <first.1>
    fsinit(ROOTDEV);
    80001a96:	4505                	li	a0,1
    80001a98:	00002097          	auipc	ra,0x2
    80001a9c:	a1e080e7          	jalr	-1506(ra) # 800034b6 <fsinit>
    80001aa0:	bff9                	j	80001a7e <forkret+0x22>

0000000080001aa2 <allocpid>:
{
    80001aa2:	1101                	addi	sp,sp,-32
    80001aa4:	ec06                	sd	ra,24(sp)
    80001aa6:	e822                	sd	s0,16(sp)
    80001aa8:	e426                	sd	s1,8(sp)
    80001aaa:	e04a                	sd	s2,0(sp)
    80001aac:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aae:	0000f917          	auipc	s2,0xf
    80001ab2:	7e290913          	addi	s2,s2,2018 # 80011290 <pid_lock>
    80001ab6:	854a                	mv	a0,s2
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	190080e7          	jalr	400(ra) # 80000c48 <acquire>
  pid = nextpid;
    80001ac0:	00007797          	auipc	a5,0x7
    80001ac4:	4e478793          	addi	a5,a5,1252 # 80008fa4 <nextpid>
    80001ac8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aca:	0014871b          	addiw	a4,s1,1
    80001ace:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ad0:	854a                	mv	a0,s2
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	22a080e7          	jalr	554(ra) # 80000cfc <release>
}
    80001ada:	8526                	mv	a0,s1
    80001adc:	60e2                	ld	ra,24(sp)
    80001ade:	6442                	ld	s0,16(sp)
    80001ae0:	64a2                	ld	s1,8(sp)
    80001ae2:	6902                	ld	s2,0(sp)
    80001ae4:	6105                	addi	sp,sp,32
    80001ae6:	8082                	ret

0000000080001ae8 <proc_pagetable>:
{
    80001ae8:	1101                	addi	sp,sp,-32
    80001aea:	ec06                	sd	ra,24(sp)
    80001aec:	e822                	sd	s0,16(sp)
    80001aee:	e426                	sd	s1,8(sp)
    80001af0:	e04a                	sd	s2,0(sp)
    80001af2:	1000                	addi	s0,sp,32
    80001af4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001af6:	00000097          	auipc	ra,0x0
    80001afa:	8aa080e7          	jalr	-1878(ra) # 800013a0 <uvmcreate>
    80001afe:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b00:	c121                	beqz	a0,80001b40 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b02:	4729                	li	a4,10
    80001b04:	00005697          	auipc	a3,0x5
    80001b08:	4fc68693          	addi	a3,a3,1276 # 80007000 <_trampoline>
    80001b0c:	6605                	lui	a2,0x1
    80001b0e:	040005b7          	lui	a1,0x4000
    80001b12:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b14:	05b2                	slli	a1,a1,0xc
    80001b16:	fffff097          	auipc	ra,0xfffff
    80001b1a:	600080e7          	jalr	1536(ra) # 80001116 <mappages>
    80001b1e:	02054863          	bltz	a0,80001b4e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b22:	4719                	li	a4,6
    80001b24:	05893683          	ld	a3,88(s2)
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	020005b7          	lui	a1,0x2000
    80001b2e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b30:	05b6                	slli	a1,a1,0xd
    80001b32:	8526                	mv	a0,s1
    80001b34:	fffff097          	auipc	ra,0xfffff
    80001b38:	5e2080e7          	jalr	1506(ra) # 80001116 <mappages>
    80001b3c:	02054163          	bltz	a0,80001b5e <proc_pagetable+0x76>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret
    uvmfree(pagetable, 0);
    80001b4e:	4581                	li	a1,0
    80001b50:	8526                	mv	a0,s1
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	a54080e7          	jalr	-1452(ra) # 800015a6 <uvmfree>
    return 0;
    80001b5a:	4481                	li	s1,0
    80001b5c:	b7d5                	j	80001b40 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b5e:	4681                	li	a3,0
    80001b60:	4605                	li	a2,1
    80001b62:	040005b7          	lui	a1,0x4000
    80001b66:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b68:	05b2                	slli	a1,a1,0xc
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	770080e7          	jalr	1904(ra) # 800012dc <uvmunmap>
    uvmfree(pagetable, 0);
    80001b74:	4581                	li	a1,0
    80001b76:	8526                	mv	a0,s1
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	a2e080e7          	jalr	-1490(ra) # 800015a6 <uvmfree>
    return 0;
    80001b80:	4481                	li	s1,0
    80001b82:	bf7d                	j	80001b40 <proc_pagetable+0x58>

0000000080001b84 <proc_freepagetable>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
    80001b90:	84aa                	mv	s1,a0
    80001b92:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b94:	4681                	li	a3,0
    80001b96:	4605                	li	a2,1
    80001b98:	040005b7          	lui	a1,0x4000
    80001b9c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b9e:	05b2                	slli	a1,a1,0xc
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	73c080e7          	jalr	1852(ra) # 800012dc <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ba8:	4681                	li	a3,0
    80001baa:	4605                	li	a2,1
    80001bac:	020005b7          	lui	a1,0x2000
    80001bb0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001bb2:	05b6                	slli	a1,a1,0xd
    80001bb4:	8526                	mv	a0,s1
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	726080e7          	jalr	1830(ra) # 800012dc <uvmunmap>
  uvmfree(pagetable, sz);
    80001bbe:	85ca                	mv	a1,s2
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	9e4080e7          	jalr	-1564(ra) # 800015a6 <uvmfree>
}
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <freeproc>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	1000                	addi	s0,sp,32
    80001be0:	84aa                	mv	s1,a0
  if (strncmp(p->name, "vm-", 3) == 0) {
    80001be2:	460d                	li	a2,3
    80001be4:	00006597          	auipc	a1,0x6
    80001be8:	61c58593          	addi	a1,a1,1564 # 80008200 <digits+0x1c0>
    80001bec:	15850513          	addi	a0,a0,344
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	224080e7          	jalr	548(ra) # 80000e14 <strncmp>
    80001bf8:	c539                	beqz	a0,80001c46 <freeproc+0x70>
  if(p->trapframe)
    80001bfa:	6ca8                	ld	a0,88(s1)
    80001bfc:	c509                	beqz	a0,80001c06 <freeproc+0x30>
    kfree((void*)p->trapframe);
    80001bfe:	fffff097          	auipc	ra,0xfffff
    80001c02:	e5c080e7          	jalr	-420(ra) # 80000a5a <kfree>
  p->trapframe = 0;
    80001c06:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0a:	68a8                	ld	a0,80(s1)
    80001c0c:	c511                	beqz	a0,80001c18 <freeproc+0x42>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0e:	64ac                	ld	a1,72(s1)
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	f74080e7          	jalr	-140(ra) # 80001b84 <proc_freepagetable>
  p->pagetable = 0;
    80001c18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c20:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c24:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c30:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c34:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c38:	0004ac23          	sw	zero,24(s1)
}
    80001c3c:	60e2                	ld	ra,24(sp)
    80001c3e:	6442                	ld	s0,16(sp)
    80001c40:	64a2                	ld	s1,8(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret
    uvmunmap(p->pagetable, memaddr_start, memaddr_count, 0);
    80001c46:	4681                	li	a3,0
    80001c48:	40000613          	li	a2,1024
    80001c4c:	4585                	li	a1,1
    80001c4e:	05fe                	slli	a1,a1,0x1f
    80001c50:	68a8                	ld	a0,80(s1)
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	68a080e7          	jalr	1674(ra) # 800012dc <uvmunmap>
    80001c5a:	b745                	j	80001bfa <freeproc+0x24>

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	00010497          	auipc	s1,0x10
    80001c6c:	a5848493          	addi	s1,s1,-1448 # 800116c0 <proc>
    80001c70:	00015917          	auipc	s2,0x15
    80001c74:	65090913          	addi	s2,s2,1616 # 800172c0 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	fce080e7          	jalr	-50(ra) # 80000c48 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	074080e7          	jalr	116(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	17048493          	addi	s1,s1,368
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a889                	j	80001cec <allocproc+0x90>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e06080e7          	jalr	-506(ra) # 80001aa2 <allocpid>
    80001ca4:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ca6:	4785                	li	a5,1
    80001ca8:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001caa:	fffff097          	auipc	ra,0xfffff
    80001cae:	eae080e7          	jalr	-338(ra) # 80000b58 <kalloc>
    80001cb2:	892a                	mv	s2,a0
    80001cb4:	eca8                	sd	a0,88(s1)
    80001cb6:	c131                	beqz	a0,80001cfa <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	e2e080e7          	jalr	-466(ra) # 80001ae8 <proc_pagetable>
    80001cc2:	892a                	mv	s2,a0
    80001cc4:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc6:	c531                	beqz	a0,80001d12 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001cc8:	07000613          	li	a2,112
    80001ccc:	4581                	li	a1,0
    80001cce:	06048513          	addi	a0,s1,96
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	072080e7          	jalr	114(ra) # 80000d44 <memset>
  p->context.ra = (uint64)forkret;
    80001cda:	00000797          	auipc	a5,0x0
    80001cde:	d8278793          	addi	a5,a5,-638 # 80001a5c <forkret>
    80001ce2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce4:	60bc                	ld	a5,64(s1)
    80001ce6:	6705                	lui	a4,0x1
    80001ce8:	97ba                	add	a5,a5,a4
    80001cea:	f4bc                	sd	a5,104(s1)
}
    80001cec:	8526                	mv	a0,s1
    80001cee:	60e2                	ld	ra,24(sp)
    80001cf0:	6442                	ld	s0,16(sp)
    80001cf2:	64a2                	ld	s1,8(sp)
    80001cf4:	6902                	ld	s2,0(sp)
    80001cf6:	6105                	addi	sp,sp,32
    80001cf8:	8082                	ret
    freeproc(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	eda080e7          	jalr	-294(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d04:	8526                	mv	a0,s1
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	ff6080e7          	jalr	-10(ra) # 80000cfc <release>
    return 0;
    80001d0e:	84ca                	mv	s1,s2
    80001d10:	bff1                	j	80001cec <allocproc+0x90>
    freeproc(p);
    80001d12:	8526                	mv	a0,s1
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	ec2080e7          	jalr	-318(ra) # 80001bd6 <freeproc>
    release(&p->lock);
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	fde080e7          	jalr	-34(ra) # 80000cfc <release>
    return 0;
    80001d26:	84ca                	mv	s1,s2
    80001d28:	b7d1                	j	80001cec <allocproc+0x90>

0000000080001d2a <userinit>:
{
    80001d2a:	1101                	addi	sp,sp,-32
    80001d2c:	ec06                	sd	ra,24(sp)
    80001d2e:	e822                	sd	s0,16(sp)
    80001d30:	e426                	sd	s1,8(sp)
    80001d32:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d34:	00000097          	auipc	ra,0x0
    80001d38:	f28080e7          	jalr	-216(ra) # 80001c5c <allocproc>
    80001d3c:	84aa                	mv	s1,a0
  initproc = p;
    80001d3e:	00007797          	auipc	a5,0x7
    80001d42:	2ca7bd23          	sd	a0,730(a5) # 80009018 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d46:	03400613          	li	a2,52
    80001d4a:	00007597          	auipc	a1,0x7
    80001d4e:	26658593          	addi	a1,a1,614 # 80008fb0 <initcode>
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	67a080e7          	jalr	1658(ra) # 800013ce <uvmfirst>
  p->sz = PGSIZE;
    80001d5c:	6785                	lui	a5,0x1
    80001d5e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d60:	6cb8                	ld	a4,88(s1)
    80001d62:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d66:	6cb8                	ld	a4,88(s1)
    80001d68:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6a:	4641                	li	a2,16
    80001d6c:	00006597          	auipc	a1,0x6
    80001d70:	49c58593          	addi	a1,a1,1180 # 80008208 <digits+0x1c8>
    80001d74:	15848513          	addi	a0,s1,344
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	114080e7          	jalr	276(ra) # 80000e8c <safestrcpy>
  p->cwd = namei("/");
    80001d80:	00006517          	auipc	a0,0x6
    80001d84:	49850513          	addi	a0,a0,1176 # 80008218 <digits+0x1d8>
    80001d88:	00002097          	auipc	ra,0x2
    80001d8c:	14c080e7          	jalr	332(ra) # 80003ed4 <namei>
    80001d90:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d94:	478d                	li	a5,3
    80001d96:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f62080e7          	jalr	-158(ra) # 80000cfc <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6105                	addi	sp,sp,32
    80001daa:	8082                	ret

0000000080001dac <growproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	e04a                	sd	s2,0(sp)
    80001db6:	1000                	addi	s0,sp,32
    80001db8:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001dba:	00000097          	auipc	ra,0x0
    80001dbe:	c6a080e7          	jalr	-918(ra) # 80001a24 <myproc>
    80001dc2:	84aa                	mv	s1,a0
  sz = p->sz;
    80001dc4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001dc6:	01204c63          	bgtz	s2,80001dde <growproc+0x32>
  } else if(n < 0){
    80001dca:	02094663          	bltz	s2,80001df6 <growproc+0x4a>
  p->sz = sz;
    80001dce:	e4ac                	sd	a1,72(s1)
  return 0;
    80001dd0:	4501                	li	a0,0
}
    80001dd2:	60e2                	ld	ra,24(sp)
    80001dd4:	6442                	ld	s0,16(sp)
    80001dd6:	64a2                	ld	s1,8(sp)
    80001dd8:	6902                	ld	s2,0(sp)
    80001dda:	6105                	addi	sp,sp,32
    80001ddc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001dde:	4691                	li	a3,4
    80001de0:	00b90633          	add	a2,s2,a1
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	6a2080e7          	jalr	1698(ra) # 80001488 <uvmalloc>
    80001dee:	85aa                	mv	a1,a0
    80001df0:	fd79                	bnez	a0,80001dce <growproc+0x22>
      return -1;
    80001df2:	557d                	li	a0,-1
    80001df4:	bff9                	j	80001dd2 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df6:	00b90633          	add	a2,s2,a1
    80001dfa:	6928                	ld	a0,80(a0)
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	644080e7          	jalr	1604(ra) # 80001440 <uvmdealloc>
    80001e04:	85aa                	mv	a1,a0
    80001e06:	b7e1                	j	80001dce <growproc+0x22>

0000000080001e08 <fork>:
{
    80001e08:	7139                	addi	sp,sp,-64
    80001e0a:	fc06                	sd	ra,56(sp)
    80001e0c:	f822                	sd	s0,48(sp)
    80001e0e:	f426                	sd	s1,40(sp)
    80001e10:	f04a                	sd	s2,32(sp)
    80001e12:	ec4e                	sd	s3,24(sp)
    80001e14:	e852                	sd	s4,16(sp)
    80001e16:	e456                	sd	s5,8(sp)
    80001e18:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c0a080e7          	jalr	-1014(ra) # 80001a24 <myproc>
    80001e22:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e38080e7          	jalr	-456(ra) # 80001c5c <allocproc>
    80001e2c:	10050c63          	beqz	a0,80001f44 <fork+0x13c>
    80001e30:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	048ab603          	ld	a2,72(s5)
    80001e36:	692c                	ld	a1,80(a0)
    80001e38:	050ab503          	ld	a0,80(s5)
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	7a4080e7          	jalr	1956(ra) # 800015e0 <uvmcopy>
    80001e44:	04054863          	bltz	a0,80001e94 <fork+0x8c>
  np->sz = p->sz;
    80001e48:	048ab783          	ld	a5,72(s5)
    80001e4c:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e50:	058ab683          	ld	a3,88(s5)
    80001e54:	87b6                	mv	a5,a3
    80001e56:	058a3703          	ld	a4,88(s4)
    80001e5a:	12068693          	addi	a3,a3,288
    80001e5e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e62:	6788                	ld	a0,8(a5)
    80001e64:	6b8c                	ld	a1,16(a5)
    80001e66:	6f90                	ld	a2,24(a5)
    80001e68:	01073023          	sd	a6,0(a4)
    80001e6c:	e708                	sd	a0,8(a4)
    80001e6e:	eb0c                	sd	a1,16(a4)
    80001e70:	ef10                	sd	a2,24(a4)
    80001e72:	02078793          	addi	a5,a5,32
    80001e76:	02070713          	addi	a4,a4,32
    80001e7a:	fed792e3          	bne	a5,a3,80001e5e <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7e:	058a3783          	ld	a5,88(s4)
    80001e82:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e86:	0d0a8493          	addi	s1,s5,208
    80001e8a:	0d0a0913          	addi	s2,s4,208
    80001e8e:	150a8993          	addi	s3,s5,336
    80001e92:	a00d                	j	80001eb4 <fork+0xac>
    freeproc(np);
    80001e94:	8552                	mv	a0,s4
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	d40080e7          	jalr	-704(ra) # 80001bd6 <freeproc>
    release(&np->lock);
    80001e9e:	8552                	mv	a0,s4
    80001ea0:	fffff097          	auipc	ra,0xfffff
    80001ea4:	e5c080e7          	jalr	-420(ra) # 80000cfc <release>
    return -1;
    80001ea8:	597d                	li	s2,-1
    80001eaa:	a059                	j	80001f30 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001eac:	04a1                	addi	s1,s1,8
    80001eae:	0921                	addi	s2,s2,8
    80001eb0:	01348b63          	beq	s1,s3,80001ec6 <fork+0xbe>
    if(p->ofile[i])
    80001eb4:	6088                	ld	a0,0(s1)
    80001eb6:	d97d                	beqz	a0,80001eac <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	68e080e7          	jalr	1678(ra) # 80004546 <filedup>
    80001ec0:	00a93023          	sd	a0,0(s2)
    80001ec4:	b7e5                	j	80001eac <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001ec6:	150ab503          	ld	a0,336(s5)
    80001eca:	00002097          	auipc	ra,0x2
    80001ece:	826080e7          	jalr	-2010(ra) # 800036f0 <idup>
    80001ed2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed6:	4641                	li	a2,16
    80001ed8:	158a8593          	addi	a1,s5,344
    80001edc:	158a0513          	addi	a0,s4,344
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	fac080e7          	jalr	-84(ra) # 80000e8c <safestrcpy>
  pid = np->pid;
    80001ee8:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001eec:	8552                	mv	a0,s4
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	e0e080e7          	jalr	-498(ra) # 80000cfc <release>
  acquire(&wait_lock);
    80001ef6:	0000f497          	auipc	s1,0xf
    80001efa:	3b248493          	addi	s1,s1,946 # 800112a8 <wait_lock>
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d48080e7          	jalr	-696(ra) # 80000c48 <acquire>
  np->parent = p;
    80001f08:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001f0c:	8526                	mv	a0,s1
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	dee080e7          	jalr	-530(ra) # 80000cfc <release>
  acquire(&np->lock);
    80001f16:	8552                	mv	a0,s4
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d30080e7          	jalr	-720(ra) # 80000c48 <acquire>
  np->state = RUNNABLE;
    80001f20:	478d                	li	a5,3
    80001f22:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001f26:	8552                	mv	a0,s4
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dd4080e7          	jalr	-556(ra) # 80000cfc <release>
}
    80001f30:	854a                	mv	a0,s2
    80001f32:	70e2                	ld	ra,56(sp)
    80001f34:	7442                	ld	s0,48(sp)
    80001f36:	74a2                	ld	s1,40(sp)
    80001f38:	7902                	ld	s2,32(sp)
    80001f3a:	69e2                	ld	s3,24(sp)
    80001f3c:	6a42                	ld	s4,16(sp)
    80001f3e:	6aa2                	ld	s5,8(sp)
    80001f40:	6121                	addi	sp,sp,64
    80001f42:	8082                	ret
    return -1;
    80001f44:	597d                	li	s2,-1
    80001f46:	b7ed                	j	80001f30 <fork+0x128>

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	addi	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	addi	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	slli	s5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	32c70713          	addi	a4,a4,812 # 80011290 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	35670713          	addi	a4,a4,854 # 800112c8 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	0000fa17          	auipc	s4,0xf
    80001f86:	30ea0a13          	addi	s4,s4,782 # 80011290 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f8c:	00015917          	auipc	s2,0x15
    80001f90:	33490913          	addi	s2,s2,820 # 800172c0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	0000f497          	auipc	s1,0xf
    80001fa4:	72048493          	addi	s1,s1,1824 # 800116c0 <proc>
    80001fa8:	a811                	j	80001fbc <scheduler+0x74>
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d50080e7          	jalr	-688(ra) # 80000cfc <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	addi	s1,s1,368
    80001fb8:	fd248ee3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c8a080e7          	jalr	-886(ra) # 80000c48 <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff3791e3          	bne	a5,s3,80001faa <scheduler+0x62>
        p->state = RUNNING;
    80001fcc:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fd0:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fd4:	06048593          	addi	a1,s1,96
    80001fd8:	8556                	mv	a0,s5
    80001fda:	00000097          	auipc	ra,0x0
    80001fde:	684080e7          	jalr	1668(ra) # 8000265e <swtch>
        c->proc = 0;
    80001fe2:	020a3823          	sd	zero,48(s4)
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	a2e080e7          	jalr	-1490(ra) # 80001a24 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	bce080e7          	jalr	-1074(ra) # 80000bce <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f717          	auipc	a4,0xf
    80002014:	28070713          	addi	a4,a4,640 # 80011290 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if(p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	0000f917          	auipc	s2,0xf
    8000203a:	25a90913          	addi	s2,s2,602 # 80011290 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	27a58593          	addi	a1,a1,634 # 800112c8 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06048513          	addi	a0,s1,96
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	602080e7          	jalr	1538(ra) # 8000265e <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	993e                	add	s2,s2,a5
    8000206c:	0b392623          	sw	s3,172(s2)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	1a250513          	addi	a0,a0,418 # 80008220 <digits+0x1e0>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4ba080e7          	jalr	1210(ra) # 80000540 <panic>
    panic("sched locks");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	1a250513          	addi	a0,a0,418 # 80008230 <digits+0x1f0>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4aa080e7          	jalr	1194(ra) # 80000540 <panic>
    panic("sched running");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	1a250513          	addi	a0,a0,418 # 80008240 <digits+0x200>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49a080e7          	jalr	1178(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	1a250513          	addi	a0,a0,418 # 80008250 <digits+0x210>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48a080e7          	jalr	1162(ra) # 80000540 <panic>

00000000800020be <yield>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	95c080e7          	jalr	-1700(ra) # 80001a24 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b76080e7          	jalr	-1162(ra) # 80000c48 <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	c14080e7          	jalr	-1004(ra) # 80000cfc <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	918080e7          	jalr	-1768(ra) # 80001a24 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	b32080e7          	jalr	-1230(ra) # 80000c48 <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	bdc080e7          	jalr	-1060(ra) # 80000cfc <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	bbe080e7          	jalr	-1090(ra) # 80000cfc <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b00080e7          	jalr	-1280(ra) # 80000c48 <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	addi	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000215e:	7139                	addi	sp,sp,-64
    80002160:	fc06                	sd	ra,56(sp)
    80002162:	f822                	sd	s0,48(sp)
    80002164:	f426                	sd	s1,40(sp)
    80002166:	f04a                	sd	s2,32(sp)
    80002168:	ec4e                	sd	s3,24(sp)
    8000216a:	e852                	sd	s4,16(sp)
    8000216c:	e456                	sd	s5,8(sp)
    8000216e:	0080                	addi	s0,sp,64
    80002170:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002172:	0000f497          	auipc	s1,0xf
    80002176:	54e48493          	addi	s1,s1,1358 # 800116c0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000217a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000217c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00015917          	auipc	s2,0x15
    80002182:	14290913          	addi	s2,s2,322 # 800172c0 <tickslock>
    80002186:	a811                	j	8000219a <wakeup+0x3c>
      }
      release(&p->lock);
    80002188:	8526                	mv	a0,s1
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b72080e7          	jalr	-1166(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002192:	17048493          	addi	s1,s1,368
    80002196:	03248663          	beq	s1,s2,800021c2 <wakeup+0x64>
    if(p != myproc()){
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	88a080e7          	jalr	-1910(ra) # 80001a24 <myproc>
    800021a2:	fea488e3          	beq	s1,a0,80002192 <wakeup+0x34>
      acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	aa0080e7          	jalr	-1376(ra) # 80000c48 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	fd379be3          	bne	a5,s3,80002188 <wakeup+0x2a>
    800021b6:	709c                	ld	a5,32(s1)
    800021b8:	fd4798e3          	bne	a5,s4,80002188 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021bc:	0154ac23          	sw	s5,24(s1)
    800021c0:	b7e1                	j	80002188 <wakeup+0x2a>
    }
  }
}
    800021c2:	70e2                	ld	ra,56(sp)
    800021c4:	7442                	ld	s0,48(sp)
    800021c6:	74a2                	ld	s1,40(sp)
    800021c8:	7902                	ld	s2,32(sp)
    800021ca:	69e2                	ld	s3,24(sp)
    800021cc:	6a42                	ld	s4,16(sp)
    800021ce:	6aa2                	ld	s5,8(sp)
    800021d0:	6121                	addi	sp,sp,64
    800021d2:	8082                	ret

00000000800021d4 <reparent>:
{
    800021d4:	7179                	addi	sp,sp,-48
    800021d6:	f406                	sd	ra,40(sp)
    800021d8:	f022                	sd	s0,32(sp)
    800021da:	ec26                	sd	s1,24(sp)
    800021dc:	e84a                	sd	s2,16(sp)
    800021de:	e44e                	sd	s3,8(sp)
    800021e0:	e052                	sd	s4,0(sp)
    800021e2:	1800                	addi	s0,sp,48
    800021e4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e6:	0000f497          	auipc	s1,0xf
    800021ea:	4da48493          	addi	s1,s1,1242 # 800116c0 <proc>
      pp->parent = initproc;
    800021ee:	00007a17          	auipc	s4,0x7
    800021f2:	e2aa0a13          	addi	s4,s4,-470 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	00015997          	auipc	s3,0x15
    800021fa:	0ca98993          	addi	s3,s3,202 # 800172c0 <tickslock>
    800021fe:	a029                	j	80002208 <reparent+0x34>
    80002200:	17048493          	addi	s1,s1,368
    80002204:	01348d63          	beq	s1,s3,8000221e <reparent+0x4a>
    if(pp->parent == p){
    80002208:	7c9c                	ld	a5,56(s1)
    8000220a:	ff279be3          	bne	a5,s2,80002200 <reparent+0x2c>
      pp->parent = initproc;
    8000220e:	000a3503          	ld	a0,0(s4)
    80002212:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f4a080e7          	jalr	-182(ra) # 8000215e <wakeup>
    8000221c:	b7d5                	j	80002200 <reparent+0x2c>
}
    8000221e:	70a2                	ld	ra,40(sp)
    80002220:	7402                	ld	s0,32(sp)
    80002222:	64e2                	ld	s1,24(sp)
    80002224:	6942                	ld	s2,16(sp)
    80002226:	69a2                	ld	s3,8(sp)
    80002228:	6a02                	ld	s4,0(sp)
    8000222a:	6145                	addi	sp,sp,48
    8000222c:	8082                	ret

000000008000222e <exit>:
{
    8000222e:	7179                	addi	sp,sp,-48
    80002230:	f406                	sd	ra,40(sp)
    80002232:	f022                	sd	s0,32(sp)
    80002234:	ec26                	sd	s1,24(sp)
    80002236:	e84a                	sd	s2,16(sp)
    80002238:	e44e                	sd	s3,8(sp)
    8000223a:	e052                	sd	s4,0(sp)
    8000223c:	1800                	addi	s0,sp,48
    8000223e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	7e4080e7          	jalr	2020(ra) # 80001a24 <myproc>
    80002248:	89aa                	mv	s3,a0
  if(p == initproc)
    8000224a:	00007797          	auipc	a5,0x7
    8000224e:	dce7b783          	ld	a5,-562(a5) # 80009018 <initproc>
    80002252:	0d050493          	addi	s1,a0,208
    80002256:	15050913          	addi	s2,a0,336
    8000225a:	02a79363          	bne	a5,a0,80002280 <exit+0x52>
    panic("init exiting");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	00a50513          	addi	a0,a0,10 # 80008268 <digits+0x228>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	2da080e7          	jalr	730(ra) # 80000540 <panic>
      fileclose(f);
    8000226e:	00002097          	auipc	ra,0x2
    80002272:	32a080e7          	jalr	810(ra) # 80004598 <fileclose>
      p->ofile[fd] = 0;
    80002276:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000227a:	04a1                	addi	s1,s1,8
    8000227c:	01248563          	beq	s1,s2,80002286 <exit+0x58>
    if(p->ofile[fd]){
    80002280:	6088                	ld	a0,0(s1)
    80002282:	f575                	bnez	a0,8000226e <exit+0x40>
    80002284:	bfdd                	j	8000227a <exit+0x4c>
  begin_op();
    80002286:	00002097          	auipc	ra,0x2
    8000228a:	e4e080e7          	jalr	-434(ra) # 800040d4 <begin_op>
  iput(p->cwd);
    8000228e:	1509b503          	ld	a0,336(s3)
    80002292:	00001097          	auipc	ra,0x1
    80002296:	656080e7          	jalr	1622(ra) # 800038e8 <iput>
  end_op();
    8000229a:	00002097          	auipc	ra,0x2
    8000229e:	eb4080e7          	jalr	-332(ra) # 8000414e <end_op>
  p->cwd = 0;
    800022a2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022a6:	0000f497          	auipc	s1,0xf
    800022aa:	00248493          	addi	s1,s1,2 # 800112a8 <wait_lock>
    800022ae:	8526                	mv	a0,s1
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	998080e7          	jalr	-1640(ra) # 80000c48 <acquire>
  reparent(p);
    800022b8:	854e                	mv	a0,s3
    800022ba:	00000097          	auipc	ra,0x0
    800022be:	f1a080e7          	jalr	-230(ra) # 800021d4 <reparent>
  wakeup(p->parent);
    800022c2:	0389b503          	ld	a0,56(s3)
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e98080e7          	jalr	-360(ra) # 8000215e <wakeup>
  acquire(&p->lock);
    800022ce:	854e                	mv	a0,s3
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	978080e7          	jalr	-1672(ra) # 80000c48 <acquire>
  p->xstate = status;
    800022d8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022dc:	4795                	li	a5,5
    800022de:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	a18080e7          	jalr	-1512(ra) # 80000cfc <release>
  sched();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	cfc080e7          	jalr	-772(ra) # 80001fe8 <sched>
  panic("zombie exit");
    800022f4:	00006517          	auipc	a0,0x6
    800022f8:	f8450513          	addi	a0,a0,-124 # 80008278 <digits+0x238>
    800022fc:	ffffe097          	auipc	ra,0xffffe
    80002300:	244080e7          	jalr	580(ra) # 80000540 <panic>

0000000080002304 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002304:	7179                	addi	sp,sp,-48
    80002306:	f406                	sd	ra,40(sp)
    80002308:	f022                	sd	s0,32(sp)
    8000230a:	ec26                	sd	s1,24(sp)
    8000230c:	e84a                	sd	s2,16(sp)
    8000230e:	e44e                	sd	s3,8(sp)
    80002310:	1800                	addi	s0,sp,48
    80002312:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	0000f497          	auipc	s1,0xf
    80002318:	3ac48493          	addi	s1,s1,940 # 800116c0 <proc>
    8000231c:	00015997          	auipc	s3,0x15
    80002320:	fa498993          	addi	s3,s3,-92 # 800172c0 <tickslock>
    acquire(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	922080e7          	jalr	-1758(ra) # 80000c48 <acquire>
    if(p->pid == pid){
    8000232e:	589c                	lw	a5,48(s1)
    80002330:	01278d63          	beq	a5,s2,8000234a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	9c6080e7          	jalr	-1594(ra) # 80000cfc <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000233e:	17048493          	addi	s1,s1,368
    80002342:	ff3491e3          	bne	s1,s3,80002324 <kill+0x20>
  }
  return -1;
    80002346:	557d                	li	a0,-1
    80002348:	a829                	j	80002362 <kill+0x5e>
      p->killed = 1;
    8000234a:	4785                	li	a5,1
    8000234c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	4789                	li	a5,2
    80002352:	00f70f63          	beq	a4,a5,80002370 <kill+0x6c>
      release(&p->lock);
    80002356:	8526                	mv	a0,s1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	9a4080e7          	jalr	-1628(ra) # 80000cfc <release>
      return 0;
    80002360:	4501                	li	a0,0
}
    80002362:	70a2                	ld	ra,40(sp)
    80002364:	7402                	ld	s0,32(sp)
    80002366:	64e2                	ld	s1,24(sp)
    80002368:	6942                	ld	s2,16(sp)
    8000236a:	69a2                	ld	s3,8(sp)
    8000236c:	6145                	addi	sp,sp,48
    8000236e:	8082                	ret
        p->state = RUNNABLE;
    80002370:	478d                	li	a5,3
    80002372:	cc9c                	sw	a5,24(s1)
    80002374:	b7cd                	j	80002356 <kill+0x52>

0000000080002376 <setkilled>:

void
setkilled(struct proc *p)
{
    80002376:	1101                	addi	sp,sp,-32
    80002378:	ec06                	sd	ra,24(sp)
    8000237a:	e822                	sd	s0,16(sp)
    8000237c:	e426                	sd	s1,8(sp)
    8000237e:	1000                	addi	s0,sp,32
    80002380:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	8c6080e7          	jalr	-1850(ra) # 80000c48 <acquire>
  p->killed = 1;
    8000238a:	4785                	li	a5,1
    8000238c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000238e:	8526                	mv	a0,s1
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	96c080e7          	jalr	-1684(ra) # 80000cfc <release>
}
    80002398:	60e2                	ld	ra,24(sp)
    8000239a:	6442                	ld	s0,16(sp)
    8000239c:	64a2                	ld	s1,8(sp)
    8000239e:	6105                	addi	sp,sp,32
    800023a0:	8082                	ret

00000000800023a2 <killed>:

int
killed(struct proc *p)
{
    800023a2:	1101                	addi	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	e04a                	sd	s2,0(sp)
    800023ac:	1000                	addi	s0,sp,32
    800023ae:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	898080e7          	jalr	-1896(ra) # 80000c48 <acquire>
  k = p->killed;
    800023b8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	93e080e7          	jalr	-1730(ra) # 80000cfc <release>
  return k;
}
    800023c6:	854a                	mv	a0,s2
    800023c8:	60e2                	ld	ra,24(sp)
    800023ca:	6442                	ld	s0,16(sp)
    800023cc:	64a2                	ld	s1,8(sp)
    800023ce:	6902                	ld	s2,0(sp)
    800023d0:	6105                	addi	sp,sp,32
    800023d2:	8082                	ret

00000000800023d4 <wait>:
{
    800023d4:	715d                	addi	sp,sp,-80
    800023d6:	e486                	sd	ra,72(sp)
    800023d8:	e0a2                	sd	s0,64(sp)
    800023da:	fc26                	sd	s1,56(sp)
    800023dc:	f84a                	sd	s2,48(sp)
    800023de:	f44e                	sd	s3,40(sp)
    800023e0:	f052                	sd	s4,32(sp)
    800023e2:	ec56                	sd	s5,24(sp)
    800023e4:	e85a                	sd	s6,16(sp)
    800023e6:	e45e                	sd	s7,8(sp)
    800023e8:	e062                	sd	s8,0(sp)
    800023ea:	0880                	addi	s0,sp,80
    800023ec:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	636080e7          	jalr	1590(ra) # 80001a24 <myproc>
    800023f6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023f8:	0000f517          	auipc	a0,0xf
    800023fc:	eb050513          	addi	a0,a0,-336 # 800112a8 <wait_lock>
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	848080e7          	jalr	-1976(ra) # 80000c48 <acquire>
    havekids = 0;
    80002408:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000240a:	4a15                	li	s4,5
        havekids = 1;
    8000240c:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000240e:	00015997          	auipc	s3,0x15
    80002412:	eb298993          	addi	s3,s3,-334 # 800172c0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002416:	0000fc17          	auipc	s8,0xf
    8000241a:	e92c0c13          	addi	s8,s8,-366 # 800112a8 <wait_lock>
    8000241e:	a0d1                	j	800024e2 <wait+0x10e>
          pid = pp->pid;
    80002420:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002424:	000b0e63          	beqz	s6,80002440 <wait+0x6c>
    80002428:	4691                	li	a3,4
    8000242a:	02c48613          	addi	a2,s1,44
    8000242e:	85da                	mv	a1,s6
    80002430:	05093503          	ld	a0,80(s2)
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	2b0080e7          	jalr	688(ra) # 800016e4 <copyout>
    8000243c:	04054163          	bltz	a0,8000247e <wait+0xaa>
          freeproc(pp);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	794080e7          	jalr	1940(ra) # 80001bd6 <freeproc>
          release(&pp->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	8b0080e7          	jalr	-1872(ra) # 80000cfc <release>
          release(&wait_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	e5450513          	addi	a0,a0,-428 # 800112a8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	8a0080e7          	jalr	-1888(ra) # 80000cfc <release>
}
    80002464:	854e                	mv	a0,s3
    80002466:	60a6                	ld	ra,72(sp)
    80002468:	6406                	ld	s0,64(sp)
    8000246a:	74e2                	ld	s1,56(sp)
    8000246c:	7942                	ld	s2,48(sp)
    8000246e:	79a2                	ld	s3,40(sp)
    80002470:	7a02                	ld	s4,32(sp)
    80002472:	6ae2                	ld	s5,24(sp)
    80002474:	6b42                	ld	s6,16(sp)
    80002476:	6ba2                	ld	s7,8(sp)
    80002478:	6c02                	ld	s8,0(sp)
    8000247a:	6161                	addi	sp,sp,80
    8000247c:	8082                	ret
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	87c080e7          	jalr	-1924(ra) # 80000cfc <release>
            release(&wait_lock);
    80002488:	0000f517          	auipc	a0,0xf
    8000248c:	e2050513          	addi	a0,a0,-480 # 800112a8 <wait_lock>
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	86c080e7          	jalr	-1940(ra) # 80000cfc <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	b7e9                	j	80002464 <wait+0x90>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xf4>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xc8>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	79c080e7          	jalr	1948(ra) # 80000c48 <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f74785e3          	beq	a5,s4,80002420 <wait+0x4c>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	840080e7          	jalr	-1984(ra) # 80000cfc <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xc8>
    if(!havekids || killed(p)){
    800024c8:	c31d                	beqz	a4,800024ee <wait+0x11a>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ed6080e7          	jalr	-298(ra) # 800023a2 <killed>
    800024d4:	ed09                	bnez	a0,800024ee <wait+0x11a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	c20080e7          	jalr	-992(ra) # 800020fa <sleep>
    havekids = 0;
    800024e2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	1dc48493          	addi	s1,s1,476 # 800116c0 <proc>
    800024ec:	bf65                	j	800024a4 <wait+0xd0>
      release(&wait_lock);
    800024ee:	0000f517          	auipc	a0,0xf
    800024f2:	dba50513          	addi	a0,a0,-582 # 800112a8 <wait_lock>
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	806080e7          	jalr	-2042(ra) # 80000cfc <release>
      return -1;
    800024fe:	59fd                	li	s3,-1
    80002500:	b795                	j	80002464 <wait+0x90>

0000000080002502 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002502:	7179                	addi	sp,sp,-48
    80002504:	f406                	sd	ra,40(sp)
    80002506:	f022                	sd	s0,32(sp)
    80002508:	ec26                	sd	s1,24(sp)
    8000250a:	e84a                	sd	s2,16(sp)
    8000250c:	e44e                	sd	s3,8(sp)
    8000250e:	e052                	sd	s4,0(sp)
    80002510:	1800                	addi	s0,sp,48
    80002512:	84aa                	mv	s1,a0
    80002514:	892e                	mv	s2,a1
    80002516:	89b2                	mv	s3,a2
    80002518:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	50a080e7          	jalr	1290(ra) # 80001a24 <myproc>
  if(user_dst){
    80002522:	c08d                	beqz	s1,80002544 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002524:	86d2                	mv	a3,s4
    80002526:	864e                	mv	a2,s3
    80002528:	85ca                	mv	a1,s2
    8000252a:	6928                	ld	a0,80(a0)
    8000252c:	fffff097          	auipc	ra,0xfffff
    80002530:	1b8080e7          	jalr	440(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002534:	70a2                	ld	ra,40(sp)
    80002536:	7402                	ld	s0,32(sp)
    80002538:	64e2                	ld	s1,24(sp)
    8000253a:	6942                	ld	s2,16(sp)
    8000253c:	69a2                	ld	s3,8(sp)
    8000253e:	6a02                	ld	s4,0(sp)
    80002540:	6145                	addi	sp,sp,48
    80002542:	8082                	ret
    memmove((char *)dst, src, len);
    80002544:	000a061b          	sext.w	a2,s4
    80002548:	85ce                	mv	a1,s3
    8000254a:	854a                	mv	a0,s2
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	854080e7          	jalr	-1964(ra) # 80000da0 <memmove>
    return 0;
    80002554:	8526                	mv	a0,s1
    80002556:	bff9                	j	80002534 <either_copyout+0x32>

0000000080002558 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002558:	7179                	addi	sp,sp,-48
    8000255a:	f406                	sd	ra,40(sp)
    8000255c:	f022                	sd	s0,32(sp)
    8000255e:	ec26                	sd	s1,24(sp)
    80002560:	e84a                	sd	s2,16(sp)
    80002562:	e44e                	sd	s3,8(sp)
    80002564:	e052                	sd	s4,0(sp)
    80002566:	1800                	addi	s0,sp,48
    80002568:	892a                	mv	s2,a0
    8000256a:	84ae                	mv	s1,a1
    8000256c:	89b2                	mv	s3,a2
    8000256e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	4b4080e7          	jalr	1204(ra) # 80001a24 <myproc>
  if(user_src){
    80002578:	c08d                	beqz	s1,8000259a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000257a:	86d2                	mv	a3,s4
    8000257c:	864e                	mv	a2,s3
    8000257e:	85ca                	mv	a1,s2
    80002580:	6928                	ld	a0,80(a0)
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	1ee080e7          	jalr	494(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret
    memmove(dst, (char*)src, len);
    8000259a:	000a061b          	sext.w	a2,s4
    8000259e:	85ce                	mv	a1,s3
    800025a0:	854a                	mv	a0,s2
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	7fe080e7          	jalr	2046(ra) # 80000da0 <memmove>
    return 0;
    800025aa:	8526                	mv	a0,s1
    800025ac:	bff9                	j	8000258a <either_copyin+0x32>

00000000800025ae <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ae:	715d                	addi	sp,sp,-80
    800025b0:	e486                	sd	ra,72(sp)
    800025b2:	e0a2                	sd	s0,64(sp)
    800025b4:	fc26                	sd	s1,56(sp)
    800025b6:	f84a                	sd	s2,48(sp)
    800025b8:	f44e                	sd	s3,40(sp)
    800025ba:	f052                	sd	s4,32(sp)
    800025bc:	ec56                	sd	s5,24(sp)
    800025be:	e85a                	sd	s6,16(sp)
    800025c0:	e45e                	sd	s7,8(sp)
    800025c2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025c4:	00006517          	auipc	a0,0x6
    800025c8:	b0450513          	addi	a0,a0,-1276 # 800080c8 <digits+0x88>
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025d4:	0000f497          	auipc	s1,0xf
    800025d8:	24448493          	addi	s1,s1,580 # 80011818 <proc+0x158>
    800025dc:	00015917          	auipc	s2,0x15
    800025e0:	e3c90913          	addi	s2,s2,-452 # 80017418 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025e6:	00006997          	auipc	s3,0x6
    800025ea:	ca298993          	addi	s3,s3,-862 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	00006a97          	auipc	s5,0x6
    800025f2:	ca2a8a93          	addi	s5,s5,-862 # 80008290 <digits+0x250>
    printf("\n");
    800025f6:	00006a17          	auipc	s4,0x6
    800025fa:	ad2a0a13          	addi	s4,s4,-1326 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	00006b97          	auipc	s7,0x6
    80002602:	cd2b8b93          	addi	s7,s7,-814 # 800082d0 <states.0>
    80002606:	a00d                	j	80002628 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002608:	ed86a583          	lw	a1,-296(a3)
    8000260c:	8556                	mv	a0,s5
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	f7c080e7          	jalr	-132(ra) # 8000058a <printf>
    printf("\n");
    80002616:	8552                	mv	a0,s4
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002620:	17048493          	addi	s1,s1,368
    80002624:	03248263          	beq	s1,s2,80002648 <procdump+0x9a>
    if(p->state == UNUSED)
    80002628:	86a6                	mv	a3,s1
    8000262a:	ec04a783          	lw	a5,-320(s1)
    8000262e:	dbed                	beqz	a5,80002620 <procdump+0x72>
      state = "???";
    80002630:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002632:	fcfb6be3          	bltu	s6,a5,80002608 <procdump+0x5a>
    80002636:	02079713          	slli	a4,a5,0x20
    8000263a:	01d75793          	srli	a5,a4,0x1d
    8000263e:	97de                	add	a5,a5,s7
    80002640:	6390                	ld	a2,0(a5)
    80002642:	f279                	bnez	a2,80002608 <procdump+0x5a>
      state = "???";
    80002644:	864e                	mv	a2,s3
    80002646:	b7c9                	j	80002608 <procdump+0x5a>
  }
}
    80002648:	60a6                	ld	ra,72(sp)
    8000264a:	6406                	ld	s0,64(sp)
    8000264c:	74e2                	ld	s1,56(sp)
    8000264e:	7942                	ld	s2,48(sp)
    80002650:	79a2                	ld	s3,40(sp)
    80002652:	7a02                	ld	s4,32(sp)
    80002654:	6ae2                	ld	s5,24(sp)
    80002656:	6b42                	ld	s6,16(sp)
    80002658:	6ba2                	ld	s7,8(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret

000000008000265e <swtch>:
    8000265e:	00153023          	sd	ra,0(a0)
    80002662:	00253423          	sd	sp,8(a0)
    80002666:	e900                	sd	s0,16(a0)
    80002668:	ed04                	sd	s1,24(a0)
    8000266a:	03253023          	sd	s2,32(a0)
    8000266e:	03353423          	sd	s3,40(a0)
    80002672:	03453823          	sd	s4,48(a0)
    80002676:	03553c23          	sd	s5,56(a0)
    8000267a:	05653023          	sd	s6,64(a0)
    8000267e:	05753423          	sd	s7,72(a0)
    80002682:	05853823          	sd	s8,80(a0)
    80002686:	05953c23          	sd	s9,88(a0)
    8000268a:	07a53023          	sd	s10,96(a0)
    8000268e:	07b53423          	sd	s11,104(a0)
    80002692:	0005b083          	ld	ra,0(a1)
    80002696:	0085b103          	ld	sp,8(a1)
    8000269a:	6980                	ld	s0,16(a1)
    8000269c:	6d84                	ld	s1,24(a1)
    8000269e:	0205b903          	ld	s2,32(a1)
    800026a2:	0285b983          	ld	s3,40(a1)
    800026a6:	0305ba03          	ld	s4,48(a1)
    800026aa:	0385ba83          	ld	s5,56(a1)
    800026ae:	0405bb03          	ld	s6,64(a1)
    800026b2:	0485bb83          	ld	s7,72(a1)
    800026b6:	0505bc03          	ld	s8,80(a1)
    800026ba:	0585bc83          	ld	s9,88(a1)
    800026be:	0605bd03          	ld	s10,96(a1)
    800026c2:	0685bd83          	ld	s11,104(a1)
    800026c6:	8082                	ret

00000000800026c8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c8:	1141                	addi	sp,sp,-16
    800026ca:	e406                	sd	ra,8(sp)
    800026cc:	e022                	sd	s0,0(sp)
    800026ce:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026d0:	00006597          	auipc	a1,0x6
    800026d4:	c3058593          	addi	a1,a1,-976 # 80008300 <states.0+0x30>
    800026d8:	00015517          	auipc	a0,0x15
    800026dc:	be850513          	addi	a0,a0,-1048 # 800172c0 <tickslock>
    800026e0:	ffffe097          	auipc	ra,0xffffe
    800026e4:	4d8080e7          	jalr	1240(ra) # 80000bb8 <initlock>
}
    800026e8:	60a2                	ld	ra,8(sp)
    800026ea:	6402                	ld	s0,0(sp)
    800026ec:	0141                	addi	sp,sp,16
    800026ee:	8082                	ret

00000000800026f0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026f0:	1141                	addi	sp,sp,-16
    800026f2:	e422                	sd	s0,8(sp)
    800026f4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f6:	00003797          	auipc	a5,0x3
    800026fa:	52a78793          	addi	a5,a5,1322 # 80005c20 <kernelvec>
    800026fe:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002702:	6422                	ld	s0,8(sp)
    80002704:	0141                	addi	sp,sp,16
    80002706:	8082                	ret

0000000080002708 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002708:	1141                	addi	sp,sp,-16
    8000270a:	e406                	sd	ra,8(sp)
    8000270c:	e022                	sd	s0,0(sp)
    8000270e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	314080e7          	jalr	788(ra) # 80001a24 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002718:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002722:	00005697          	auipc	a3,0x5
    80002726:	8de68693          	addi	a3,a3,-1826 # 80007000 <_trampoline>
    8000272a:	00005717          	auipc	a4,0x5
    8000272e:	8d670713          	addi	a4,a4,-1834 # 80007000 <_trampoline>
    80002732:	8f15                	sub	a4,a4,a3
    80002734:	040007b7          	lui	a5,0x4000
    80002738:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000273a:	07b2                	slli	a5,a5,0xc
    8000273c:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273e:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002744:	18002673          	csrr	a2,satp
    80002748:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000274a:	6d30                	ld	a2,88(a0)
    8000274c:	6138                	ld	a4,64(a0)
    8000274e:	6585                	lui	a1,0x1
    80002750:	972e                	add	a4,a4,a1
    80002752:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002754:	6d38                	ld	a4,88(a0)
    80002756:	00000617          	auipc	a2,0x0
    8000275a:	13460613          	addi	a2,a2,308 # 8000288a <usertrap>
    8000275e:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002760:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002762:	8612                	mv	a2,tp
    80002764:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002766:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000276a:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276e:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002772:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002776:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002778:	6f18                	ld	a4,24(a4)
    8000277a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277e:	6928                	ld	a0,80(a0)
    80002780:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002782:	00005717          	auipc	a4,0x5
    80002786:	91a70713          	addi	a4,a4,-1766 # 8000709c <userret>
    8000278a:	8f15                	sub	a4,a4,a3
    8000278c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000278e:	577d                	li	a4,-1
    80002790:	177e                	slli	a4,a4,0x3f
    80002792:	8d59                	or	a0,a0,a4
    80002794:	9782                	jalr	a5
}
    80002796:	60a2                	ld	ra,8(sp)
    80002798:	6402                	ld	s0,0(sp)
    8000279a:	0141                	addi	sp,sp,16
    8000279c:	8082                	ret

000000008000279e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279e:	1101                	addi	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	e426                	sd	s1,8(sp)
    800027a6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a8:	00015497          	auipc	s1,0x15
    800027ac:	b1848493          	addi	s1,s1,-1256 # 800172c0 <tickslock>
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	496080e7          	jalr	1174(ra) # 80000c48 <acquire>
  ticks++;
    800027ba:	00007517          	auipc	a0,0x7
    800027be:	86650513          	addi	a0,a0,-1946 # 80009020 <ticks>
    800027c2:	411c                	lw	a5,0(a0)
    800027c4:	2785                	addiw	a5,a5,1
    800027c6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c8:	00000097          	auipc	ra,0x0
    800027cc:	996080e7          	jalr	-1642(ra) # 8000215e <wakeup>
  release(&tickslock);
    800027d0:	8526                	mv	a0,s1
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	52a080e7          	jalr	1322(ra) # 80000cfc <release>
}
    800027da:	60e2                	ld	ra,24(sp)
    800027dc:	6442                	ld	s0,16(sp)
    800027de:	64a2                	ld	s1,8(sp)
    800027e0:	6105                	addi	sp,sp,32
    800027e2:	8082                	ret

00000000800027e4 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e4:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027e8:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    800027ea:	0807df63          	bgez	a5,80002888 <devintr+0xa4>
{
    800027ee:	1101                	addi	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    800027f8:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    800027fc:	46a5                	li	a3,9
    800027fe:	00d70d63          	beq	a4,a3,80002818 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002802:	577d                	li	a4,-1
    80002804:	177e                	slli	a4,a4,0x3f
    80002806:	0705                	addi	a4,a4,1
    return 0;
    80002808:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280a:	04e78e63          	beq	a5,a4,80002866 <devintr+0x82>
  }
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret
    int irq = plic_claim();
    80002818:	00003097          	auipc	ra,0x3
    8000281c:	510080e7          	jalr	1296(ra) # 80005d28 <plic_claim>
    80002820:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002822:	47a9                	li	a5,10
    80002824:	02f50763          	beq	a0,a5,80002852 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002828:	4785                	li	a5,1
    8000282a:	02f50963          	beq	a0,a5,8000285c <devintr+0x78>
    return 1;
    8000282e:	4505                	li	a0,1
    } else if(irq){
    80002830:	dcf9                	beqz	s1,8000280e <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002832:	85a6                	mv	a1,s1
    80002834:	00006517          	auipc	a0,0x6
    80002838:	ad450513          	addi	a0,a0,-1324 # 80008308 <states.0+0x38>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	d4e080e7          	jalr	-690(ra) # 8000058a <printf>
      plic_complete(irq);
    80002844:	8526                	mv	a0,s1
    80002846:	00003097          	auipc	ra,0x3
    8000284a:	506080e7          	jalr	1286(ra) # 80005d4c <plic_complete>
    return 1;
    8000284e:	4505                	li	a0,1
    80002850:	bf7d                	j	8000280e <devintr+0x2a>
      uartintr();
    80002852:	ffffe097          	auipc	ra,0xffffe
    80002856:	1b8080e7          	jalr	440(ra) # 80000a0a <uartintr>
    if(irq)
    8000285a:	b7ed                	j	80002844 <devintr+0x60>
      virtio_disk_intr();
    8000285c:	00004097          	auipc	ra,0x4
    80002860:	b68080e7          	jalr	-1176(ra) # 800063c4 <virtio_disk_intr>
    if(irq)
    80002864:	b7c5                	j	80002844 <devintr+0x60>
    if(cpuid() == 0){
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	192080e7          	jalr	402(ra) # 800019f8 <cpuid>
    8000286e:	c901                	beqz	a0,8000287e <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002870:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002874:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002876:	14479073          	csrw	sip,a5
    return 2;
    8000287a:	4509                	li	a0,2
    8000287c:	bf49                	j	8000280e <devintr+0x2a>
      clockintr();
    8000287e:	00000097          	auipc	ra,0x0
    80002882:	f20080e7          	jalr	-224(ra) # 8000279e <clockintr>
    80002886:	b7ed                	j	80002870 <devintr+0x8c>
}
    80002888:	8082                	ret

000000008000288a <usertrap>:
{
    8000288a:	1101                	addi	sp,sp,-32
    8000288c:	ec06                	sd	ra,24(sp)
    8000288e:	e822                	sd	s0,16(sp)
    80002890:	e426                	sd	s1,8(sp)
    80002892:	e04a                	sd	s2,0(sp)
    80002894:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002896:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000289a:	1007f793          	andi	a5,a5,256
    8000289e:	ebad                	bnez	a5,80002910 <usertrap+0x86>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	00003797          	auipc	a5,0x3
    800028a4:	38078793          	addi	a5,a5,896 # 80005c20 <kernelvec>
    800028a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ac:	fffff097          	auipc	ra,0xfffff
    800028b0:	178080e7          	jalr	376(ra) # 80001a24 <myproc>
    800028b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b8:	14102773          	csrr	a4,sepc
    800028bc:	ef98                	sd	a4,24(a5)
  if(strncmp(p->name, "vm-", 3) == 0 && (r_scause() == 2 || r_scause() == 1)){
    800028be:	15850913          	addi	s2,a0,344
    800028c2:	460d                	li	a2,3
    800028c4:	00006597          	auipc	a1,0x6
    800028c8:	93c58593          	addi	a1,a1,-1732 # 80008200 <digits+0x1c0>
    800028cc:	854a                	mv	a0,s2
    800028ce:	ffffe097          	auipc	ra,0xffffe
    800028d2:	546080e7          	jalr	1350(ra) # 80000e14 <strncmp>
    800028d6:	e919                	bnez	a0,800028ec <usertrap+0x62>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d8:	14202773          	csrr	a4,scause
    800028dc:	4789                	li	a5,2
    800028de:	04f70163          	beq	a4,a5,80002920 <usertrap+0x96>
    800028e2:	14202773          	csrr	a4,scause
    800028e6:	4785                	li	a5,1
    800028e8:	02f70c63          	beq	a4,a5,80002920 <usertrap+0x96>
    800028ec:	14202773          	csrr	a4,scause
  else if(r_scause() == 8){
    800028f0:	47a1                	li	a5,8
    800028f2:	02f70c63          	beq	a4,a5,8000292a <usertrap+0xa0>
  } else if((which_dev = devintr()) != 0){
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	eee080e7          	jalr	-274(ra) # 800027e4 <devintr>
    800028fe:	892a                	mv	s2,a0
    80002900:	c155                	beqz	a0,800029a4 <usertrap+0x11a>
  if(killed(p))
    80002902:	8526                	mv	a0,s1
    80002904:	00000097          	auipc	ra,0x0
    80002908:	a9e080e7          	jalr	-1378(ra) # 800023a2 <killed>
    8000290c:	cd79                	beqz	a0,800029ea <usertrap+0x160>
    8000290e:	a8c9                	j	800029e0 <usertrap+0x156>
    panic("usertrap: not from user mode");
    80002910:	00006517          	auipc	a0,0x6
    80002914:	a1850513          	addi	a0,a0,-1512 # 80008328 <states.0+0x58>
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	c28080e7          	jalr	-984(ra) # 80000540 <panic>
    trap_and_emulate();
    80002920:	00004097          	auipc	ra,0x4
    80002924:	398080e7          	jalr	920(ra) # 80006cb8 <trap_and_emulate>
    80002928:	a081                	j	80002968 <usertrap+0xde>
    if (strncmp(p->name, "vm-", 3) == 0) {
    8000292a:	460d                	li	a2,3
    8000292c:	00006597          	auipc	a1,0x6
    80002930:	8d458593          	addi	a1,a1,-1836 # 80008200 <digits+0x1c0>
    80002934:	854a                	mv	a0,s2
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	4de080e7          	jalr	1246(ra) # 80000e14 <strncmp>
    8000293e:	c529                	beqz	a0,80002988 <usertrap+0xfe>
    if(killed(p))
    80002940:	8526                	mv	a0,s1
    80002942:	00000097          	auipc	ra,0x0
    80002946:	a60080e7          	jalr	-1440(ra) # 800023a2 <killed>
    8000294a:	e539                	bnez	a0,80002998 <usertrap+0x10e>
    p->trapframe->epc += 4;
    8000294c:	6cb8                	ld	a4,88(s1)
    8000294e:	6f1c                	ld	a5,24(a4)
    80002950:	0791                	addi	a5,a5,4
    80002952:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002954:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002958:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295c:	10079073          	csrw	sstatus,a5
    syscall();
    80002960:	00000097          	auipc	ra,0x0
    80002964:	2e4080e7          	jalr	740(ra) # 80002c44 <syscall>
  if(killed(p))
    80002968:	8526                	mv	a0,s1
    8000296a:	00000097          	auipc	ra,0x0
    8000296e:	a38080e7          	jalr	-1480(ra) # 800023a2 <killed>
    80002972:	e535                	bnez	a0,800029de <usertrap+0x154>
  usertrapret();
    80002974:	00000097          	auipc	ra,0x0
    80002978:	d94080e7          	jalr	-620(ra) # 80002708 <usertrapret>
}
    8000297c:	60e2                	ld	ra,24(sp)
    8000297e:	6442                	ld	s0,16(sp)
    80002980:	64a2                	ld	s1,8(sp)
    80002982:	6902                	ld	s2,0(sp)
    80002984:	6105                	addi	sp,sp,32
    80002986:	8082                	ret
      p->proc_te_vm = 1;
    80002988:	4785                	li	a5,1
    8000298a:	16f4a423          	sw	a5,360(s1)
      trap_and_emulate();
    8000298e:	00004097          	auipc	ra,0x4
    80002992:	32a080e7          	jalr	810(ra) # 80006cb8 <trap_and_emulate>
    80002996:	b76d                	j	80002940 <usertrap+0xb6>
      exit(-1);
    80002998:	557d                	li	a0,-1
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	894080e7          	jalr	-1900(ra) # 8000222e <exit>
    800029a2:	b76d                	j	8000294c <usertrap+0xc2>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a4:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029a8:	5890                	lw	a2,48(s1)
    800029aa:	00006517          	auipc	a0,0x6
    800029ae:	99e50513          	addi	a0,a0,-1634 # 80008348 <states.0+0x78>
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	bd8080e7          	jalr	-1064(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ba:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029be:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	9b650513          	addi	a0,a0,-1610 # 80008378 <states.0+0xa8>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	bc0080e7          	jalr	-1088(ra) # 8000058a <printf>
    setkilled(p);
    800029d2:	8526                	mv	a0,s1
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	9a2080e7          	jalr	-1630(ra) # 80002376 <setkilled>
    800029dc:	b771                	j	80002968 <usertrap+0xde>
  if(killed(p))
    800029de:	4901                	li	s2,0
    exit(-1);
    800029e0:	557d                	li	a0,-1
    800029e2:	00000097          	auipc	ra,0x0
    800029e6:	84c080e7          	jalr	-1972(ra) # 8000222e <exit>
  if(which_dev == 2)
    800029ea:	4789                	li	a5,2
    800029ec:	f8f914e3          	bne	s2,a5,80002974 <usertrap+0xea>
    yield();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	6ce080e7          	jalr	1742(ra) # 800020be <yield>
    800029f8:	bfb5                	j	80002974 <usertrap+0xea>

00000000800029fa <kerneltrap>:
{
    800029fa:	7179                	addi	sp,sp,-48
    800029fc:	f406                	sd	ra,40(sp)
    800029fe:	f022                	sd	s0,32(sp)
    80002a00:	ec26                	sd	s1,24(sp)
    80002a02:	e84a                	sd	s2,16(sp)
    80002a04:	e44e                	sd	s3,8(sp)
    80002a06:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a08:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a10:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a14:	1004f793          	andi	a5,s1,256
    80002a18:	cb85                	beqz	a5,80002a48 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a1a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a1e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a20:	ef85                	bnez	a5,80002a58 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a22:	00000097          	auipc	ra,0x0
    80002a26:	dc2080e7          	jalr	-574(ra) # 800027e4 <devintr>
    80002a2a:	cd1d                	beqz	a0,80002a68 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2c:	4789                	li	a5,2
    80002a2e:	06f50a63          	beq	a0,a5,80002aa2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a32:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a36:	10049073          	csrw	sstatus,s1
}
    80002a3a:	70a2                	ld	ra,40(sp)
    80002a3c:	7402                	ld	s0,32(sp)
    80002a3e:	64e2                	ld	s1,24(sp)
    80002a40:	6942                	ld	s2,16(sp)
    80002a42:	69a2                	ld	s3,8(sp)
    80002a44:	6145                	addi	sp,sp,48
    80002a46:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	95050513          	addi	a0,a0,-1712 # 80008398 <states.0+0xc8>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	af0080e7          	jalr	-1296(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	96850513          	addi	a0,a0,-1688 # 800083c0 <states.0+0xf0>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	ae0080e7          	jalr	-1312(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a68:	85ce                	mv	a1,s3
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	97650513          	addi	a0,a0,-1674 # 800083e0 <states.0+0x110>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b18080e7          	jalr	-1256(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a7a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a7e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	96e50513          	addi	a0,a0,-1682 # 800083f0 <states.0+0x120>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b00080e7          	jalr	-1280(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	97650513          	addi	a0,a0,-1674 # 80008408 <states.0+0x138>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	aa6080e7          	jalr	-1370(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002aa2:	fffff097          	auipc	ra,0xfffff
    80002aa6:	f82080e7          	jalr	-126(ra) # 80001a24 <myproc>
    80002aaa:	d541                	beqz	a0,80002a32 <kerneltrap+0x38>
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	f78080e7          	jalr	-136(ra) # 80001a24 <myproc>
    80002ab4:	4d18                	lw	a4,24(a0)
    80002ab6:	4791                	li	a5,4
    80002ab8:	f6f71de3          	bne	a4,a5,80002a32 <kerneltrap+0x38>
    yield();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	602080e7          	jalr	1538(ra) # 800020be <yield>
    80002ac4:	b7bd                	j	80002a32 <kerneltrap+0x38>

0000000080002ac6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	1000                	addi	s0,sp,32
    80002ad0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	f52080e7          	jalr	-174(ra) # 80001a24 <myproc>
  switch (n) {
    80002ada:	4795                	li	a5,5
    80002adc:	0497e163          	bltu	a5,s1,80002b1e <argraw+0x58>
    80002ae0:	048a                	slli	s1,s1,0x2
    80002ae2:	00006717          	auipc	a4,0x6
    80002ae6:	95e70713          	addi	a4,a4,-1698 # 80008440 <states.0+0x170>
    80002aea:	94ba                	add	s1,s1,a4
    80002aec:	409c                	lw	a5,0(s1)
    80002aee:	97ba                	add	a5,a5,a4
    80002af0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002af2:	6d3c                	ld	a5,88(a0)
    80002af4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002af6:	60e2                	ld	ra,24(sp)
    80002af8:	6442                	ld	s0,16(sp)
    80002afa:	64a2                	ld	s1,8(sp)
    80002afc:	6105                	addi	sp,sp,32
    80002afe:	8082                	ret
    return p->trapframe->a1;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	7fa8                	ld	a0,120(a5)
    80002b04:	bfcd                	j	80002af6 <argraw+0x30>
    return p->trapframe->a2;
    80002b06:	6d3c                	ld	a5,88(a0)
    80002b08:	63c8                	ld	a0,128(a5)
    80002b0a:	b7f5                	j	80002af6 <argraw+0x30>
    return p->trapframe->a3;
    80002b0c:	6d3c                	ld	a5,88(a0)
    80002b0e:	67c8                	ld	a0,136(a5)
    80002b10:	b7dd                	j	80002af6 <argraw+0x30>
    return p->trapframe->a4;
    80002b12:	6d3c                	ld	a5,88(a0)
    80002b14:	6bc8                	ld	a0,144(a5)
    80002b16:	b7c5                	j	80002af6 <argraw+0x30>
    return p->trapframe->a5;
    80002b18:	6d3c                	ld	a5,88(a0)
    80002b1a:	6fc8                	ld	a0,152(a5)
    80002b1c:	bfe9                	j	80002af6 <argraw+0x30>
  panic("argraw");
    80002b1e:	00006517          	auipc	a0,0x6
    80002b22:	8fa50513          	addi	a0,a0,-1798 # 80008418 <states.0+0x148>
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	a1a080e7          	jalr	-1510(ra) # 80000540 <panic>

0000000080002b2e <fetchaddr>:
{
    80002b2e:	1101                	addi	sp,sp,-32
    80002b30:	ec06                	sd	ra,24(sp)
    80002b32:	e822                	sd	s0,16(sp)
    80002b34:	e426                	sd	s1,8(sp)
    80002b36:	e04a                	sd	s2,0(sp)
    80002b38:	1000                	addi	s0,sp,32
    80002b3a:	84aa                	mv	s1,a0
    80002b3c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	ee6080e7          	jalr	-282(ra) # 80001a24 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b46:	653c                	ld	a5,72(a0)
    80002b48:	02f4f863          	bgeu	s1,a5,80002b78 <fetchaddr+0x4a>
    80002b4c:	00848713          	addi	a4,s1,8
    80002b50:	02e7e663          	bltu	a5,a4,80002b7c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b54:	46a1                	li	a3,8
    80002b56:	8626                	mv	a2,s1
    80002b58:	85ca                	mv	a1,s2
    80002b5a:	6928                	ld	a0,80(a0)
    80002b5c:	fffff097          	auipc	ra,0xfffff
    80002b60:	c14080e7          	jalr	-1004(ra) # 80001770 <copyin>
    80002b64:	00a03533          	snez	a0,a0
    80002b68:	40a00533          	neg	a0,a0
}
    80002b6c:	60e2                	ld	ra,24(sp)
    80002b6e:	6442                	ld	s0,16(sp)
    80002b70:	64a2                	ld	s1,8(sp)
    80002b72:	6902                	ld	s2,0(sp)
    80002b74:	6105                	addi	sp,sp,32
    80002b76:	8082                	ret
    return -1;
    80002b78:	557d                	li	a0,-1
    80002b7a:	bfcd                	j	80002b6c <fetchaddr+0x3e>
    80002b7c:	557d                	li	a0,-1
    80002b7e:	b7fd                	j	80002b6c <fetchaddr+0x3e>

0000000080002b80 <fetchstr>:
{
    80002b80:	7179                	addi	sp,sp,-48
    80002b82:	f406                	sd	ra,40(sp)
    80002b84:	f022                	sd	s0,32(sp)
    80002b86:	ec26                	sd	s1,24(sp)
    80002b88:	e84a                	sd	s2,16(sp)
    80002b8a:	e44e                	sd	s3,8(sp)
    80002b8c:	1800                	addi	s0,sp,48
    80002b8e:	892a                	mv	s2,a0
    80002b90:	84ae                	mv	s1,a1
    80002b92:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	e90080e7          	jalr	-368(ra) # 80001a24 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b9c:	86ce                	mv	a3,s3
    80002b9e:	864a                	mv	a2,s2
    80002ba0:	85a6                	mv	a1,s1
    80002ba2:	6928                	ld	a0,80(a0)
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	c5a080e7          	jalr	-934(ra) # 800017fe <copyinstr>
    80002bac:	00054e63          	bltz	a0,80002bc8 <fetchstr+0x48>
  return strlen(buf);
    80002bb0:	8526                	mv	a0,s1
    80002bb2:	ffffe097          	auipc	ra,0xffffe
    80002bb6:	30c080e7          	jalr	780(ra) # 80000ebe <strlen>
}
    80002bba:	70a2                	ld	ra,40(sp)
    80002bbc:	7402                	ld	s0,32(sp)
    80002bbe:	64e2                	ld	s1,24(sp)
    80002bc0:	6942                	ld	s2,16(sp)
    80002bc2:	69a2                	ld	s3,8(sp)
    80002bc4:	6145                	addi	sp,sp,48
    80002bc6:	8082                	ret
    return -1;
    80002bc8:	557d                	li	a0,-1
    80002bca:	bfc5                	j	80002bba <fetchstr+0x3a>

0000000080002bcc <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bcc:	1101                	addi	sp,sp,-32
    80002bce:	ec06                	sd	ra,24(sp)
    80002bd0:	e822                	sd	s0,16(sp)
    80002bd2:	e426                	sd	s1,8(sp)
    80002bd4:	1000                	addi	s0,sp,32
    80002bd6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	eee080e7          	jalr	-274(ra) # 80002ac6 <argraw>
    80002be0:	c088                	sw	a0,0(s1)
}
    80002be2:	60e2                	ld	ra,24(sp)
    80002be4:	6442                	ld	s0,16(sp)
    80002be6:	64a2                	ld	s1,8(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	1000                	addi	s0,sp,32
    80002bf6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	ece080e7          	jalr	-306(ra) # 80002ac6 <argraw>
    80002c00:	e088                	sd	a0,0(s1)
}
    80002c02:	60e2                	ld	ra,24(sp)
    80002c04:	6442                	ld	s0,16(sp)
    80002c06:	64a2                	ld	s1,8(sp)
    80002c08:	6105                	addi	sp,sp,32
    80002c0a:	8082                	ret

0000000080002c0c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c0c:	7179                	addi	sp,sp,-48
    80002c0e:	f406                	sd	ra,40(sp)
    80002c10:	f022                	sd	s0,32(sp)
    80002c12:	ec26                	sd	s1,24(sp)
    80002c14:	e84a                	sd	s2,16(sp)
    80002c16:	1800                	addi	s0,sp,48
    80002c18:	84ae                	mv	s1,a1
    80002c1a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c1c:	fd840593          	addi	a1,s0,-40
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	fcc080e7          	jalr	-52(ra) # 80002bec <argaddr>
  return fetchstr(addr, buf, max);
    80002c28:	864a                	mv	a2,s2
    80002c2a:	85a6                	mv	a1,s1
    80002c2c:	fd843503          	ld	a0,-40(s0)
    80002c30:	00000097          	auipc	ra,0x0
    80002c34:	f50080e7          	jalr	-176(ra) # 80002b80 <fetchstr>
}
    80002c38:	70a2                	ld	ra,40(sp)
    80002c3a:	7402                	ld	s0,32(sp)
    80002c3c:	64e2                	ld	s1,24(sp)
    80002c3e:	6942                	ld	s2,16(sp)
    80002c40:	6145                	addi	sp,sp,48
    80002c42:	8082                	ret

0000000080002c44 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	e426                	sd	s1,8(sp)
    80002c4c:	e04a                	sd	s2,0(sp)
    80002c4e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	dd4080e7          	jalr	-556(ra) # 80001a24 <myproc>
    80002c58:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c5a:	05853903          	ld	s2,88(a0)
    80002c5e:	0a893783          	ld	a5,168(s2)
    80002c62:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c66:	37fd                	addiw	a5,a5,-1
    80002c68:	4751                	li	a4,20
    80002c6a:	00f76f63          	bltu	a4,a5,80002c88 <syscall+0x44>
    80002c6e:	00369713          	slli	a4,a3,0x3
    80002c72:	00005797          	auipc	a5,0x5
    80002c76:	7e678793          	addi	a5,a5,2022 # 80008458 <syscalls>
    80002c7a:	97ba                	add	a5,a5,a4
    80002c7c:	639c                	ld	a5,0(a5)
    80002c7e:	c789                	beqz	a5,80002c88 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c80:	9782                	jalr	a5
    80002c82:	06a93823          	sd	a0,112(s2)
    80002c86:	a839                	j	80002ca4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c88:	15848613          	addi	a2,s1,344
    80002c8c:	588c                	lw	a1,48(s1)
    80002c8e:	00005517          	auipc	a0,0x5
    80002c92:	79250513          	addi	a0,a0,1938 # 80008420 <states.0+0x150>
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	8f4080e7          	jalr	-1804(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c9e:	6cbc                	ld	a5,88(s1)
    80002ca0:	577d                	li	a4,-1
    80002ca2:	fbb8                	sd	a4,112(a5)
  }
}
    80002ca4:	60e2                	ld	ra,24(sp)
    80002ca6:	6442                	ld	s0,16(sp)
    80002ca8:	64a2                	ld	s1,8(sp)
    80002caa:	6902                	ld	s2,0(sp)
    80002cac:	6105                	addi	sp,sp,32
    80002cae:	8082                	ret

0000000080002cb0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cb0:	1101                	addi	sp,sp,-32
    80002cb2:	ec06                	sd	ra,24(sp)
    80002cb4:	e822                	sd	s0,16(sp)
    80002cb6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cb8:	fec40593          	addi	a1,s0,-20
    80002cbc:	4501                	li	a0,0
    80002cbe:	00000097          	auipc	ra,0x0
    80002cc2:	f0e080e7          	jalr	-242(ra) # 80002bcc <argint>
  exit(n);
    80002cc6:	fec42503          	lw	a0,-20(s0)
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	564080e7          	jalr	1380(ra) # 8000222e <exit>
  return 0;  // not reached
}
    80002cd2:	4501                	li	a0,0
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	6105                	addi	sp,sp,32
    80002cda:	8082                	ret

0000000080002cdc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cdc:	1141                	addi	sp,sp,-16
    80002cde:	e406                	sd	ra,8(sp)
    80002ce0:	e022                	sd	s0,0(sp)
    80002ce2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	d40080e7          	jalr	-704(ra) # 80001a24 <myproc>
}
    80002cec:	5908                	lw	a0,48(a0)
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_fork>:

uint64
sys_fork(void)
{
    80002cf6:	1141                	addi	sp,sp,-16
    80002cf8:	e406                	sd	ra,8(sp)
    80002cfa:	e022                	sd	s0,0(sp)
    80002cfc:	0800                	addi	s0,sp,16
  return fork();
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	10a080e7          	jalr	266(ra) # 80001e08 <fork>
}
    80002d06:	60a2                	ld	ra,8(sp)
    80002d08:	6402                	ld	s0,0(sp)
    80002d0a:	0141                	addi	sp,sp,16
    80002d0c:	8082                	ret

0000000080002d0e <sys_wait>:

uint64
sys_wait(void)
{
    80002d0e:	1101                	addi	sp,sp,-32
    80002d10:	ec06                	sd	ra,24(sp)
    80002d12:	e822                	sd	s0,16(sp)
    80002d14:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d16:	fe840593          	addi	a1,s0,-24
    80002d1a:	4501                	li	a0,0
    80002d1c:	00000097          	auipc	ra,0x0
    80002d20:	ed0080e7          	jalr	-304(ra) # 80002bec <argaddr>
  return wait(p);
    80002d24:	fe843503          	ld	a0,-24(s0)
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	6ac080e7          	jalr	1708(ra) # 800023d4 <wait>
}
    80002d30:	60e2                	ld	ra,24(sp)
    80002d32:	6442                	ld	s0,16(sp)
    80002d34:	6105                	addi	sp,sp,32
    80002d36:	8082                	ret

0000000080002d38 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d38:	7179                	addi	sp,sp,-48
    80002d3a:	f406                	sd	ra,40(sp)
    80002d3c:	f022                	sd	s0,32(sp)
    80002d3e:	ec26                	sd	s1,24(sp)
    80002d40:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d42:	fdc40593          	addi	a1,s0,-36
    80002d46:	4501                	li	a0,0
    80002d48:	00000097          	auipc	ra,0x0
    80002d4c:	e84080e7          	jalr	-380(ra) # 80002bcc <argint>
  addr = myproc()->sz;
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	cd4080e7          	jalr	-812(ra) # 80001a24 <myproc>
    80002d58:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d5a:	fdc42503          	lw	a0,-36(s0)
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	04e080e7          	jalr	78(ra) # 80001dac <growproc>
    80002d66:	00054863          	bltz	a0,80002d76 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d6a:	8526                	mv	a0,s1
    80002d6c:	70a2                	ld	ra,40(sp)
    80002d6e:	7402                	ld	s0,32(sp)
    80002d70:	64e2                	ld	s1,24(sp)
    80002d72:	6145                	addi	sp,sp,48
    80002d74:	8082                	ret
    return -1;
    80002d76:	54fd                	li	s1,-1
    80002d78:	bfcd                	j	80002d6a <sys_sbrk+0x32>

0000000080002d7a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d7a:	7139                	addi	sp,sp,-64
    80002d7c:	fc06                	sd	ra,56(sp)
    80002d7e:	f822                	sd	s0,48(sp)
    80002d80:	f426                	sd	s1,40(sp)
    80002d82:	f04a                	sd	s2,32(sp)
    80002d84:	ec4e                	sd	s3,24(sp)
    80002d86:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d88:	fcc40593          	addi	a1,s0,-52
    80002d8c:	4501                	li	a0,0
    80002d8e:	00000097          	auipc	ra,0x0
    80002d92:	e3e080e7          	jalr	-450(ra) # 80002bcc <argint>
  acquire(&tickslock);
    80002d96:	00014517          	auipc	a0,0x14
    80002d9a:	52a50513          	addi	a0,a0,1322 # 800172c0 <tickslock>
    80002d9e:	ffffe097          	auipc	ra,0xffffe
    80002da2:	eaa080e7          	jalr	-342(ra) # 80000c48 <acquire>
  ticks0 = ticks;
    80002da6:	00006917          	auipc	s2,0x6
    80002daa:	27a92903          	lw	s2,634(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002dae:	fcc42783          	lw	a5,-52(s0)
    80002db2:	cf9d                	beqz	a5,80002df0 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002db4:	00014997          	auipc	s3,0x14
    80002db8:	50c98993          	addi	s3,s3,1292 # 800172c0 <tickslock>
    80002dbc:	00006497          	auipc	s1,0x6
    80002dc0:	26448493          	addi	s1,s1,612 # 80009020 <ticks>
    if(killed(myproc())){
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	c60080e7          	jalr	-928(ra) # 80001a24 <myproc>
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	5d6080e7          	jalr	1494(ra) # 800023a2 <killed>
    80002dd4:	ed15                	bnez	a0,80002e10 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002dd6:	85ce                	mv	a1,s3
    80002dd8:	8526                	mv	a0,s1
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	320080e7          	jalr	800(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    80002de2:	409c                	lw	a5,0(s1)
    80002de4:	412787bb          	subw	a5,a5,s2
    80002de8:	fcc42703          	lw	a4,-52(s0)
    80002dec:	fce7ece3          	bltu	a5,a4,80002dc4 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002df0:	00014517          	auipc	a0,0x14
    80002df4:	4d050513          	addi	a0,a0,1232 # 800172c0 <tickslock>
    80002df8:	ffffe097          	auipc	ra,0xffffe
    80002dfc:	f04080e7          	jalr	-252(ra) # 80000cfc <release>
  return 0;
    80002e00:	4501                	li	a0,0
}
    80002e02:	70e2                	ld	ra,56(sp)
    80002e04:	7442                	ld	s0,48(sp)
    80002e06:	74a2                	ld	s1,40(sp)
    80002e08:	7902                	ld	s2,32(sp)
    80002e0a:	69e2                	ld	s3,24(sp)
    80002e0c:	6121                	addi	sp,sp,64
    80002e0e:	8082                	ret
      release(&tickslock);
    80002e10:	00014517          	auipc	a0,0x14
    80002e14:	4b050513          	addi	a0,a0,1200 # 800172c0 <tickslock>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	ee4080e7          	jalr	-284(ra) # 80000cfc <release>
      return -1;
    80002e20:	557d                	li	a0,-1
    80002e22:	b7c5                	j	80002e02 <sys_sleep+0x88>

0000000080002e24 <sys_kill>:

uint64
sys_kill(void)
{
    80002e24:	1101                	addi	sp,sp,-32
    80002e26:	ec06                	sd	ra,24(sp)
    80002e28:	e822                	sd	s0,16(sp)
    80002e2a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e2c:	fec40593          	addi	a1,s0,-20
    80002e30:	4501                	li	a0,0
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	d9a080e7          	jalr	-614(ra) # 80002bcc <argint>
  return kill(pid);
    80002e3a:	fec42503          	lw	a0,-20(s0)
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	4c6080e7          	jalr	1222(ra) # 80002304 <kill>
}
    80002e46:	60e2                	ld	ra,24(sp)
    80002e48:	6442                	ld	s0,16(sp)
    80002e4a:	6105                	addi	sp,sp,32
    80002e4c:	8082                	ret

0000000080002e4e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e58:	00014517          	auipc	a0,0x14
    80002e5c:	46850513          	addi	a0,a0,1128 # 800172c0 <tickslock>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	de8080e7          	jalr	-536(ra) # 80000c48 <acquire>
  xticks = ticks;
    80002e68:	00006497          	auipc	s1,0x6
    80002e6c:	1b84a483          	lw	s1,440(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e70:	00014517          	auipc	a0,0x14
    80002e74:	45050513          	addi	a0,a0,1104 # 800172c0 <tickslock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	e84080e7          	jalr	-380(ra) # 80000cfc <release>
  return xticks;
}
    80002e80:	02049513          	slli	a0,s1,0x20
    80002e84:	9101                	srli	a0,a0,0x20
    80002e86:	60e2                	ld	ra,24(sp)
    80002e88:	6442                	ld	s0,16(sp)
    80002e8a:	64a2                	ld	s1,8(sp)
    80002e8c:	6105                	addi	sp,sp,32
    80002e8e:	8082                	ret

0000000080002e90 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e90:	7179                	addi	sp,sp,-48
    80002e92:	f406                	sd	ra,40(sp)
    80002e94:	f022                	sd	s0,32(sp)
    80002e96:	ec26                	sd	s1,24(sp)
    80002e98:	e84a                	sd	s2,16(sp)
    80002e9a:	e44e                	sd	s3,8(sp)
    80002e9c:	e052                	sd	s4,0(sp)
    80002e9e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ea0:	00005597          	auipc	a1,0x5
    80002ea4:	66858593          	addi	a1,a1,1640 # 80008508 <syscalls+0xb0>
    80002ea8:	00014517          	auipc	a0,0x14
    80002eac:	43050513          	addi	a0,a0,1072 # 800172d8 <bcache>
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	d08080e7          	jalr	-760(ra) # 80000bb8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eb8:	0001c797          	auipc	a5,0x1c
    80002ebc:	42078793          	addi	a5,a5,1056 # 8001f2d8 <bcache+0x8000>
    80002ec0:	0001c717          	auipc	a4,0x1c
    80002ec4:	68070713          	addi	a4,a4,1664 # 8001f540 <bcache+0x8268>
    80002ec8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ecc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed0:	00014497          	auipc	s1,0x14
    80002ed4:	42048493          	addi	s1,s1,1056 # 800172f0 <bcache+0x18>
    b->next = bcache.head.next;
    80002ed8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002eda:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002edc:	00005a17          	auipc	s4,0x5
    80002ee0:	634a0a13          	addi	s4,s4,1588 # 80008510 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002ee4:	2b893783          	ld	a5,696(s2)
    80002ee8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eea:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002eee:	85d2                	mv	a1,s4
    80002ef0:	01048513          	addi	a0,s1,16
    80002ef4:	00001097          	auipc	ra,0x1
    80002ef8:	496080e7          	jalr	1174(ra) # 8000438a <initsleeplock>
    bcache.head.next->prev = b;
    80002efc:	2b893783          	ld	a5,696(s2)
    80002f00:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f02:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f06:	45848493          	addi	s1,s1,1112
    80002f0a:	fd349de3          	bne	s1,s3,80002ee4 <binit+0x54>
  }
}
    80002f0e:	70a2                	ld	ra,40(sp)
    80002f10:	7402                	ld	s0,32(sp)
    80002f12:	64e2                	ld	s1,24(sp)
    80002f14:	6942                	ld	s2,16(sp)
    80002f16:	69a2                	ld	s3,8(sp)
    80002f18:	6a02                	ld	s4,0(sp)
    80002f1a:	6145                	addi	sp,sp,48
    80002f1c:	8082                	ret

0000000080002f1e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f1e:	7179                	addi	sp,sp,-48
    80002f20:	f406                	sd	ra,40(sp)
    80002f22:	f022                	sd	s0,32(sp)
    80002f24:	ec26                	sd	s1,24(sp)
    80002f26:	e84a                	sd	s2,16(sp)
    80002f28:	e44e                	sd	s3,8(sp)
    80002f2a:	1800                	addi	s0,sp,48
    80002f2c:	892a                	mv	s2,a0
    80002f2e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f30:	00014517          	auipc	a0,0x14
    80002f34:	3a850513          	addi	a0,a0,936 # 800172d8 <bcache>
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	d10080e7          	jalr	-752(ra) # 80000c48 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f40:	0001c497          	auipc	s1,0x1c
    80002f44:	6504b483          	ld	s1,1616(s1) # 8001f590 <bcache+0x82b8>
    80002f48:	0001c797          	auipc	a5,0x1c
    80002f4c:	5f878793          	addi	a5,a5,1528 # 8001f540 <bcache+0x8268>
    80002f50:	02f48f63          	beq	s1,a5,80002f8e <bread+0x70>
    80002f54:	873e                	mv	a4,a5
    80002f56:	a021                	j	80002f5e <bread+0x40>
    80002f58:	68a4                	ld	s1,80(s1)
    80002f5a:	02e48a63          	beq	s1,a4,80002f8e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f5e:	449c                	lw	a5,8(s1)
    80002f60:	ff279ce3          	bne	a5,s2,80002f58 <bread+0x3a>
    80002f64:	44dc                	lw	a5,12(s1)
    80002f66:	ff3799e3          	bne	a5,s3,80002f58 <bread+0x3a>
      b->refcnt++;
    80002f6a:	40bc                	lw	a5,64(s1)
    80002f6c:	2785                	addiw	a5,a5,1
    80002f6e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f70:	00014517          	auipc	a0,0x14
    80002f74:	36850513          	addi	a0,a0,872 # 800172d8 <bcache>
    80002f78:	ffffe097          	auipc	ra,0xffffe
    80002f7c:	d84080e7          	jalr	-636(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002f80:	01048513          	addi	a0,s1,16
    80002f84:	00001097          	auipc	ra,0x1
    80002f88:	440080e7          	jalr	1088(ra) # 800043c4 <acquiresleep>
      return b;
    80002f8c:	a8b9                	j	80002fea <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f8e:	0001c497          	auipc	s1,0x1c
    80002f92:	5fa4b483          	ld	s1,1530(s1) # 8001f588 <bcache+0x82b0>
    80002f96:	0001c797          	auipc	a5,0x1c
    80002f9a:	5aa78793          	addi	a5,a5,1450 # 8001f540 <bcache+0x8268>
    80002f9e:	00f48863          	beq	s1,a5,80002fae <bread+0x90>
    80002fa2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fa4:	40bc                	lw	a5,64(s1)
    80002fa6:	cf81                	beqz	a5,80002fbe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa8:	64a4                	ld	s1,72(s1)
    80002faa:	fee49de3          	bne	s1,a4,80002fa4 <bread+0x86>
  panic("bget: no buffers");
    80002fae:	00005517          	auipc	a0,0x5
    80002fb2:	56a50513          	addi	a0,a0,1386 # 80008518 <syscalls+0xc0>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	58a080e7          	jalr	1418(ra) # 80000540 <panic>
      b->dev = dev;
    80002fbe:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002fc2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002fc6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fca:	4785                	li	a5,1
    80002fcc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	30a50513          	addi	a0,a0,778 # 800172d8 <bcache>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	d26080e7          	jalr	-730(ra) # 80000cfc <release>
      acquiresleep(&b->lock);
    80002fde:	01048513          	addi	a0,s1,16
    80002fe2:	00001097          	auipc	ra,0x1
    80002fe6:	3e2080e7          	jalr	994(ra) # 800043c4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fea:	409c                	lw	a5,0(s1)
    80002fec:	cb89                	beqz	a5,80002ffe <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002fee:	8526                	mv	a0,s1
    80002ff0:	70a2                	ld	ra,40(sp)
    80002ff2:	7402                	ld	s0,32(sp)
    80002ff4:	64e2                	ld	s1,24(sp)
    80002ff6:	6942                	ld	s2,16(sp)
    80002ff8:	69a2                	ld	s3,8(sp)
    80002ffa:	6145                	addi	sp,sp,48
    80002ffc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ffe:	4581                	li	a1,0
    80003000:	8526                	mv	a0,s1
    80003002:	00003097          	auipc	ra,0x3
    80003006:	192080e7          	jalr	402(ra) # 80006194 <virtio_disk_rw>
    b->valid = 1;
    8000300a:	4785                	li	a5,1
    8000300c:	c09c                	sw	a5,0(s1)
  return b;
    8000300e:	b7c5                	j	80002fee <bread+0xd0>

0000000080003010 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003010:	1101                	addi	sp,sp,-32
    80003012:	ec06                	sd	ra,24(sp)
    80003014:	e822                	sd	s0,16(sp)
    80003016:	e426                	sd	s1,8(sp)
    80003018:	1000                	addi	s0,sp,32
    8000301a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000301c:	0541                	addi	a0,a0,16
    8000301e:	00001097          	auipc	ra,0x1
    80003022:	440080e7          	jalr	1088(ra) # 8000445e <holdingsleep>
    80003026:	cd01                	beqz	a0,8000303e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003028:	4585                	li	a1,1
    8000302a:	8526                	mv	a0,s1
    8000302c:	00003097          	auipc	ra,0x3
    80003030:	168080e7          	jalr	360(ra) # 80006194 <virtio_disk_rw>
}
    80003034:	60e2                	ld	ra,24(sp)
    80003036:	6442                	ld	s0,16(sp)
    80003038:	64a2                	ld	s1,8(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret
    panic("bwrite");
    8000303e:	00005517          	auipc	a0,0x5
    80003042:	4f250513          	addi	a0,a0,1266 # 80008530 <syscalls+0xd8>
    80003046:	ffffd097          	auipc	ra,0xffffd
    8000304a:	4fa080e7          	jalr	1274(ra) # 80000540 <panic>

000000008000304e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000304e:	1101                	addi	sp,sp,-32
    80003050:	ec06                	sd	ra,24(sp)
    80003052:	e822                	sd	s0,16(sp)
    80003054:	e426                	sd	s1,8(sp)
    80003056:	e04a                	sd	s2,0(sp)
    80003058:	1000                	addi	s0,sp,32
    8000305a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000305c:	01050913          	addi	s2,a0,16
    80003060:	854a                	mv	a0,s2
    80003062:	00001097          	auipc	ra,0x1
    80003066:	3fc080e7          	jalr	1020(ra) # 8000445e <holdingsleep>
    8000306a:	c925                	beqz	a0,800030da <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000306c:	854a                	mv	a0,s2
    8000306e:	00001097          	auipc	ra,0x1
    80003072:	3ac080e7          	jalr	940(ra) # 8000441a <releasesleep>

  acquire(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	26250513          	addi	a0,a0,610 # 800172d8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	bca080e7          	jalr	-1078(ra) # 80000c48 <acquire>
  b->refcnt--;
    80003086:	40bc                	lw	a5,64(s1)
    80003088:	37fd                	addiw	a5,a5,-1
    8000308a:	0007871b          	sext.w	a4,a5
    8000308e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003090:	e71d                	bnez	a4,800030be <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003092:	68b8                	ld	a4,80(s1)
    80003094:	64bc                	ld	a5,72(s1)
    80003096:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003098:	68b8                	ld	a4,80(s1)
    8000309a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000309c:	0001c797          	auipc	a5,0x1c
    800030a0:	23c78793          	addi	a5,a5,572 # 8001f2d8 <bcache+0x8000>
    800030a4:	2b87b703          	ld	a4,696(a5)
    800030a8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030aa:	0001c717          	auipc	a4,0x1c
    800030ae:	49670713          	addi	a4,a4,1174 # 8001f540 <bcache+0x8268>
    800030b2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030b4:	2b87b703          	ld	a4,696(a5)
    800030b8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030ba:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030be:	00014517          	auipc	a0,0x14
    800030c2:	21a50513          	addi	a0,a0,538 # 800172d8 <bcache>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	c36080e7          	jalr	-970(ra) # 80000cfc <release>
}
    800030ce:	60e2                	ld	ra,24(sp)
    800030d0:	6442                	ld	s0,16(sp)
    800030d2:	64a2                	ld	s1,8(sp)
    800030d4:	6902                	ld	s2,0(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret
    panic("brelse");
    800030da:	00005517          	auipc	a0,0x5
    800030de:	45e50513          	addi	a0,a0,1118 # 80008538 <syscalls+0xe0>
    800030e2:	ffffd097          	auipc	ra,0xffffd
    800030e6:	45e080e7          	jalr	1118(ra) # 80000540 <panic>

00000000800030ea <bpin>:

void
bpin(struct buf *b) {
    800030ea:	1101                	addi	sp,sp,-32
    800030ec:	ec06                	sd	ra,24(sp)
    800030ee:	e822                	sd	s0,16(sp)
    800030f0:	e426                	sd	s1,8(sp)
    800030f2:	1000                	addi	s0,sp,32
    800030f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800030f6:	00014517          	auipc	a0,0x14
    800030fa:	1e250513          	addi	a0,a0,482 # 800172d8 <bcache>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	b4a080e7          	jalr	-1206(ra) # 80000c48 <acquire>
  b->refcnt++;
    80003106:	40bc                	lw	a5,64(s1)
    80003108:	2785                	addiw	a5,a5,1
    8000310a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000310c:	00014517          	auipc	a0,0x14
    80003110:	1cc50513          	addi	a0,a0,460 # 800172d8 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	be8080e7          	jalr	-1048(ra) # 80000cfc <release>
}
    8000311c:	60e2                	ld	ra,24(sp)
    8000311e:	6442                	ld	s0,16(sp)
    80003120:	64a2                	ld	s1,8(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret

0000000080003126 <bunpin>:

void
bunpin(struct buf *b) {
    80003126:	1101                	addi	sp,sp,-32
    80003128:	ec06                	sd	ra,24(sp)
    8000312a:	e822                	sd	s0,16(sp)
    8000312c:	e426                	sd	s1,8(sp)
    8000312e:	1000                	addi	s0,sp,32
    80003130:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003132:	00014517          	auipc	a0,0x14
    80003136:	1a650513          	addi	a0,a0,422 # 800172d8 <bcache>
    8000313a:	ffffe097          	auipc	ra,0xffffe
    8000313e:	b0e080e7          	jalr	-1266(ra) # 80000c48 <acquire>
  b->refcnt--;
    80003142:	40bc                	lw	a5,64(s1)
    80003144:	37fd                	addiw	a5,a5,-1
    80003146:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003148:	00014517          	auipc	a0,0x14
    8000314c:	19050513          	addi	a0,a0,400 # 800172d8 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	bac080e7          	jalr	-1108(ra) # 80000cfc <release>
}
    80003158:	60e2                	ld	ra,24(sp)
    8000315a:	6442                	ld	s0,16(sp)
    8000315c:	64a2                	ld	s1,8(sp)
    8000315e:	6105                	addi	sp,sp,32
    80003160:	8082                	ret

0000000080003162 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	e426                	sd	s1,8(sp)
    8000316a:	e04a                	sd	s2,0(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003170:	00d5d59b          	srliw	a1,a1,0xd
    80003174:	0001d797          	auipc	a5,0x1d
    80003178:	8407a783          	lw	a5,-1984(a5) # 8001f9b4 <sb+0x1c>
    8000317c:	9dbd                	addw	a1,a1,a5
    8000317e:	00000097          	auipc	ra,0x0
    80003182:	da0080e7          	jalr	-608(ra) # 80002f1e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003186:	0074f713          	andi	a4,s1,7
    8000318a:	4785                	li	a5,1
    8000318c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003190:	14ce                	slli	s1,s1,0x33
    80003192:	90d9                	srli	s1,s1,0x36
    80003194:	00950733          	add	a4,a0,s1
    80003198:	05874703          	lbu	a4,88(a4)
    8000319c:	00e7f6b3          	and	a3,a5,a4
    800031a0:	c69d                	beqz	a3,800031ce <bfree+0x6c>
    800031a2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031a4:	94aa                	add	s1,s1,a0
    800031a6:	fff7c793          	not	a5,a5
    800031aa:	8f7d                	and	a4,a4,a5
    800031ac:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031b0:	00001097          	auipc	ra,0x1
    800031b4:	0f6080e7          	jalr	246(ra) # 800042a6 <log_write>
  brelse(bp);
    800031b8:	854a                	mv	a0,s2
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	e94080e7          	jalr	-364(ra) # 8000304e <brelse>
}
    800031c2:	60e2                	ld	ra,24(sp)
    800031c4:	6442                	ld	s0,16(sp)
    800031c6:	64a2                	ld	s1,8(sp)
    800031c8:	6902                	ld	s2,0(sp)
    800031ca:	6105                	addi	sp,sp,32
    800031cc:	8082                	ret
    panic("freeing free block");
    800031ce:	00005517          	auipc	a0,0x5
    800031d2:	37250513          	addi	a0,a0,882 # 80008540 <syscalls+0xe8>
    800031d6:	ffffd097          	auipc	ra,0xffffd
    800031da:	36a080e7          	jalr	874(ra) # 80000540 <panic>

00000000800031de <balloc>:
{
    800031de:	711d                	addi	sp,sp,-96
    800031e0:	ec86                	sd	ra,88(sp)
    800031e2:	e8a2                	sd	s0,80(sp)
    800031e4:	e4a6                	sd	s1,72(sp)
    800031e6:	e0ca                	sd	s2,64(sp)
    800031e8:	fc4e                	sd	s3,56(sp)
    800031ea:	f852                	sd	s4,48(sp)
    800031ec:	f456                	sd	s5,40(sp)
    800031ee:	f05a                	sd	s6,32(sp)
    800031f0:	ec5e                	sd	s7,24(sp)
    800031f2:	e862                	sd	s8,16(sp)
    800031f4:	e466                	sd	s9,8(sp)
    800031f6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800031f8:	0001c797          	auipc	a5,0x1c
    800031fc:	7a47a783          	lw	a5,1956(a5) # 8001f99c <sb+0x4>
    80003200:	cff5                	beqz	a5,800032fc <balloc+0x11e>
    80003202:	8baa                	mv	s7,a0
    80003204:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003206:	0001cb17          	auipc	s6,0x1c
    8000320a:	792b0b13          	addi	s6,s6,1938 # 8001f998 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000320e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003210:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003212:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003214:	6c89                	lui	s9,0x2
    80003216:	a061                	j	8000329e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003218:	97ca                	add	a5,a5,s2
    8000321a:	8e55                	or	a2,a2,a3
    8000321c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003220:	854a                	mv	a0,s2
    80003222:	00001097          	auipc	ra,0x1
    80003226:	084080e7          	jalr	132(ra) # 800042a6 <log_write>
        brelse(bp);
    8000322a:	854a                	mv	a0,s2
    8000322c:	00000097          	auipc	ra,0x0
    80003230:	e22080e7          	jalr	-478(ra) # 8000304e <brelse>
  bp = bread(dev, bno);
    80003234:	85a6                	mv	a1,s1
    80003236:	855e                	mv	a0,s7
    80003238:	00000097          	auipc	ra,0x0
    8000323c:	ce6080e7          	jalr	-794(ra) # 80002f1e <bread>
    80003240:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003242:	40000613          	li	a2,1024
    80003246:	4581                	li	a1,0
    80003248:	05850513          	addi	a0,a0,88
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	af8080e7          	jalr	-1288(ra) # 80000d44 <memset>
  log_write(bp);
    80003254:	854a                	mv	a0,s2
    80003256:	00001097          	auipc	ra,0x1
    8000325a:	050080e7          	jalr	80(ra) # 800042a6 <log_write>
  brelse(bp);
    8000325e:	854a                	mv	a0,s2
    80003260:	00000097          	auipc	ra,0x0
    80003264:	dee080e7          	jalr	-530(ra) # 8000304e <brelse>
}
    80003268:	8526                	mv	a0,s1
    8000326a:	60e6                	ld	ra,88(sp)
    8000326c:	6446                	ld	s0,80(sp)
    8000326e:	64a6                	ld	s1,72(sp)
    80003270:	6906                	ld	s2,64(sp)
    80003272:	79e2                	ld	s3,56(sp)
    80003274:	7a42                	ld	s4,48(sp)
    80003276:	7aa2                	ld	s5,40(sp)
    80003278:	7b02                	ld	s6,32(sp)
    8000327a:	6be2                	ld	s7,24(sp)
    8000327c:	6c42                	ld	s8,16(sp)
    8000327e:	6ca2                	ld	s9,8(sp)
    80003280:	6125                	addi	sp,sp,96
    80003282:	8082                	ret
    brelse(bp);
    80003284:	854a                	mv	a0,s2
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	dc8080e7          	jalr	-568(ra) # 8000304e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000328e:	015c87bb          	addw	a5,s9,s5
    80003292:	00078a9b          	sext.w	s5,a5
    80003296:	004b2703          	lw	a4,4(s6)
    8000329a:	06eaf163          	bgeu	s5,a4,800032fc <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000329e:	41fad79b          	sraiw	a5,s5,0x1f
    800032a2:	0137d79b          	srliw	a5,a5,0x13
    800032a6:	015787bb          	addw	a5,a5,s5
    800032aa:	40d7d79b          	sraiw	a5,a5,0xd
    800032ae:	01cb2583          	lw	a1,28(s6)
    800032b2:	9dbd                	addw	a1,a1,a5
    800032b4:	855e                	mv	a0,s7
    800032b6:	00000097          	auipc	ra,0x0
    800032ba:	c68080e7          	jalr	-920(ra) # 80002f1e <bread>
    800032be:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032c0:	004b2503          	lw	a0,4(s6)
    800032c4:	000a849b          	sext.w	s1,s5
    800032c8:	8762                	mv	a4,s8
    800032ca:	faa4fde3          	bgeu	s1,a0,80003284 <balloc+0xa6>
      m = 1 << (bi % 8);
    800032ce:	00777693          	andi	a3,a4,7
    800032d2:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032d6:	41f7579b          	sraiw	a5,a4,0x1f
    800032da:	01d7d79b          	srliw	a5,a5,0x1d
    800032de:	9fb9                	addw	a5,a5,a4
    800032e0:	4037d79b          	sraiw	a5,a5,0x3
    800032e4:	00f90633          	add	a2,s2,a5
    800032e8:	05864603          	lbu	a2,88(a2)
    800032ec:	00c6f5b3          	and	a1,a3,a2
    800032f0:	d585                	beqz	a1,80003218 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f2:	2705                	addiw	a4,a4,1
    800032f4:	2485                	addiw	s1,s1,1
    800032f6:	fd471ae3          	bne	a4,s4,800032ca <balloc+0xec>
    800032fa:	b769                	j	80003284 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800032fc:	00005517          	auipc	a0,0x5
    80003300:	25c50513          	addi	a0,a0,604 # 80008558 <syscalls+0x100>
    80003304:	ffffd097          	auipc	ra,0xffffd
    80003308:	286080e7          	jalr	646(ra) # 8000058a <printf>
  return 0;
    8000330c:	4481                	li	s1,0
    8000330e:	bfa9                	j	80003268 <balloc+0x8a>

0000000080003310 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003310:	7179                	addi	sp,sp,-48
    80003312:	f406                	sd	ra,40(sp)
    80003314:	f022                	sd	s0,32(sp)
    80003316:	ec26                	sd	s1,24(sp)
    80003318:	e84a                	sd	s2,16(sp)
    8000331a:	e44e                	sd	s3,8(sp)
    8000331c:	e052                	sd	s4,0(sp)
    8000331e:	1800                	addi	s0,sp,48
    80003320:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003322:	47ad                	li	a5,11
    80003324:	02b7e863          	bltu	a5,a1,80003354 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003328:	02059793          	slli	a5,a1,0x20
    8000332c:	01e7d593          	srli	a1,a5,0x1e
    80003330:	00b504b3          	add	s1,a0,a1
    80003334:	0504a903          	lw	s2,80(s1)
    80003338:	06091e63          	bnez	s2,800033b4 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000333c:	4108                	lw	a0,0(a0)
    8000333e:	00000097          	auipc	ra,0x0
    80003342:	ea0080e7          	jalr	-352(ra) # 800031de <balloc>
    80003346:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000334a:	06090563          	beqz	s2,800033b4 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000334e:	0524a823          	sw	s2,80(s1)
    80003352:	a08d                	j	800033b4 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003354:	ff45849b          	addiw	s1,a1,-12
    80003358:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000335c:	0ff00793          	li	a5,255
    80003360:	08e7e563          	bltu	a5,a4,800033ea <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003364:	08052903          	lw	s2,128(a0)
    80003368:	00091d63          	bnez	s2,80003382 <bmap+0x72>
      addr = balloc(ip->dev);
    8000336c:	4108                	lw	a0,0(a0)
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	e70080e7          	jalr	-400(ra) # 800031de <balloc>
    80003376:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000337a:	02090d63          	beqz	s2,800033b4 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000337e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003382:	85ca                	mv	a1,s2
    80003384:	0009a503          	lw	a0,0(s3)
    80003388:	00000097          	auipc	ra,0x0
    8000338c:	b96080e7          	jalr	-1130(ra) # 80002f1e <bread>
    80003390:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003392:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003396:	02049713          	slli	a4,s1,0x20
    8000339a:	01e75593          	srli	a1,a4,0x1e
    8000339e:	00b784b3          	add	s1,a5,a1
    800033a2:	0004a903          	lw	s2,0(s1)
    800033a6:	02090063          	beqz	s2,800033c6 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033aa:	8552                	mv	a0,s4
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	ca2080e7          	jalr	-862(ra) # 8000304e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033b4:	854a                	mv	a0,s2
    800033b6:	70a2                	ld	ra,40(sp)
    800033b8:	7402                	ld	s0,32(sp)
    800033ba:	64e2                	ld	s1,24(sp)
    800033bc:	6942                	ld	s2,16(sp)
    800033be:	69a2                	ld	s3,8(sp)
    800033c0:	6a02                	ld	s4,0(sp)
    800033c2:	6145                	addi	sp,sp,48
    800033c4:	8082                	ret
      addr = balloc(ip->dev);
    800033c6:	0009a503          	lw	a0,0(s3)
    800033ca:	00000097          	auipc	ra,0x0
    800033ce:	e14080e7          	jalr	-492(ra) # 800031de <balloc>
    800033d2:	0005091b          	sext.w	s2,a0
      if(addr){
    800033d6:	fc090ae3          	beqz	s2,800033aa <bmap+0x9a>
        a[bn] = addr;
    800033da:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800033de:	8552                	mv	a0,s4
    800033e0:	00001097          	auipc	ra,0x1
    800033e4:	ec6080e7          	jalr	-314(ra) # 800042a6 <log_write>
    800033e8:	b7c9                	j	800033aa <bmap+0x9a>
  panic("bmap: out of range");
    800033ea:	00005517          	auipc	a0,0x5
    800033ee:	18650513          	addi	a0,a0,390 # 80008570 <syscalls+0x118>
    800033f2:	ffffd097          	auipc	ra,0xffffd
    800033f6:	14e080e7          	jalr	334(ra) # 80000540 <panic>

00000000800033fa <iget>:
{
    800033fa:	7179                	addi	sp,sp,-48
    800033fc:	f406                	sd	ra,40(sp)
    800033fe:	f022                	sd	s0,32(sp)
    80003400:	ec26                	sd	s1,24(sp)
    80003402:	e84a                	sd	s2,16(sp)
    80003404:	e44e                	sd	s3,8(sp)
    80003406:	e052                	sd	s4,0(sp)
    80003408:	1800                	addi	s0,sp,48
    8000340a:	89aa                	mv	s3,a0
    8000340c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000340e:	0001c517          	auipc	a0,0x1c
    80003412:	5aa50513          	addi	a0,a0,1450 # 8001f9b8 <itable>
    80003416:	ffffe097          	auipc	ra,0xffffe
    8000341a:	832080e7          	jalr	-1998(ra) # 80000c48 <acquire>
  empty = 0;
    8000341e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003420:	0001c497          	auipc	s1,0x1c
    80003424:	5b048493          	addi	s1,s1,1456 # 8001f9d0 <itable+0x18>
    80003428:	0001e697          	auipc	a3,0x1e
    8000342c:	03868693          	addi	a3,a3,56 # 80021460 <log>
    80003430:	a039                	j	8000343e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003432:	02090b63          	beqz	s2,80003468 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003436:	08848493          	addi	s1,s1,136
    8000343a:	02d48a63          	beq	s1,a3,8000346e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000343e:	449c                	lw	a5,8(s1)
    80003440:	fef059e3          	blez	a5,80003432 <iget+0x38>
    80003444:	4098                	lw	a4,0(s1)
    80003446:	ff3716e3          	bne	a4,s3,80003432 <iget+0x38>
    8000344a:	40d8                	lw	a4,4(s1)
    8000344c:	ff4713e3          	bne	a4,s4,80003432 <iget+0x38>
      ip->ref++;
    80003450:	2785                	addiw	a5,a5,1
    80003452:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003454:	0001c517          	auipc	a0,0x1c
    80003458:	56450513          	addi	a0,a0,1380 # 8001f9b8 <itable>
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	8a0080e7          	jalr	-1888(ra) # 80000cfc <release>
      return ip;
    80003464:	8926                	mv	s2,s1
    80003466:	a03d                	j	80003494 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003468:	f7f9                	bnez	a5,80003436 <iget+0x3c>
    8000346a:	8926                	mv	s2,s1
    8000346c:	b7e9                	j	80003436 <iget+0x3c>
  if(empty == 0)
    8000346e:	02090c63          	beqz	s2,800034a6 <iget+0xac>
  ip->dev = dev;
    80003472:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003476:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000347a:	4785                	li	a5,1
    8000347c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003480:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003484:	0001c517          	auipc	a0,0x1c
    80003488:	53450513          	addi	a0,a0,1332 # 8001f9b8 <itable>
    8000348c:	ffffe097          	auipc	ra,0xffffe
    80003490:	870080e7          	jalr	-1936(ra) # 80000cfc <release>
}
    80003494:	854a                	mv	a0,s2
    80003496:	70a2                	ld	ra,40(sp)
    80003498:	7402                	ld	s0,32(sp)
    8000349a:	64e2                	ld	s1,24(sp)
    8000349c:	6942                	ld	s2,16(sp)
    8000349e:	69a2                	ld	s3,8(sp)
    800034a0:	6a02                	ld	s4,0(sp)
    800034a2:	6145                	addi	sp,sp,48
    800034a4:	8082                	ret
    panic("iget: no inodes");
    800034a6:	00005517          	auipc	a0,0x5
    800034aa:	0e250513          	addi	a0,a0,226 # 80008588 <syscalls+0x130>
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	092080e7          	jalr	146(ra) # 80000540 <panic>

00000000800034b6 <fsinit>:
fsinit(int dev) {
    800034b6:	7179                	addi	sp,sp,-48
    800034b8:	f406                	sd	ra,40(sp)
    800034ba:	f022                	sd	s0,32(sp)
    800034bc:	ec26                	sd	s1,24(sp)
    800034be:	e84a                	sd	s2,16(sp)
    800034c0:	e44e                	sd	s3,8(sp)
    800034c2:	1800                	addi	s0,sp,48
    800034c4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034c6:	4585                	li	a1,1
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	a56080e7          	jalr	-1450(ra) # 80002f1e <bread>
    800034d0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034d2:	0001c997          	auipc	s3,0x1c
    800034d6:	4c698993          	addi	s3,s3,1222 # 8001f998 <sb>
    800034da:	02000613          	li	a2,32
    800034de:	05850593          	addi	a1,a0,88
    800034e2:	854e                	mv	a0,s3
    800034e4:	ffffe097          	auipc	ra,0xffffe
    800034e8:	8bc080e7          	jalr	-1860(ra) # 80000da0 <memmove>
  brelse(bp);
    800034ec:	8526                	mv	a0,s1
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	b60080e7          	jalr	-1184(ra) # 8000304e <brelse>
  if(sb.magic != FSMAGIC)
    800034f6:	0009a703          	lw	a4,0(s3)
    800034fa:	102037b7          	lui	a5,0x10203
    800034fe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003502:	02f71263          	bne	a4,a5,80003526 <fsinit+0x70>
  initlog(dev, &sb);
    80003506:	0001c597          	auipc	a1,0x1c
    8000350a:	49258593          	addi	a1,a1,1170 # 8001f998 <sb>
    8000350e:	854a                	mv	a0,s2
    80003510:	00001097          	auipc	ra,0x1
    80003514:	b2c080e7          	jalr	-1236(ra) # 8000403c <initlog>
}
    80003518:	70a2                	ld	ra,40(sp)
    8000351a:	7402                	ld	s0,32(sp)
    8000351c:	64e2                	ld	s1,24(sp)
    8000351e:	6942                	ld	s2,16(sp)
    80003520:	69a2                	ld	s3,8(sp)
    80003522:	6145                	addi	sp,sp,48
    80003524:	8082                	ret
    panic("invalid file system");
    80003526:	00005517          	auipc	a0,0x5
    8000352a:	07250513          	addi	a0,a0,114 # 80008598 <syscalls+0x140>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	012080e7          	jalr	18(ra) # 80000540 <panic>

0000000080003536 <iinit>:
{
    80003536:	7179                	addi	sp,sp,-48
    80003538:	f406                	sd	ra,40(sp)
    8000353a:	f022                	sd	s0,32(sp)
    8000353c:	ec26                	sd	s1,24(sp)
    8000353e:	e84a                	sd	s2,16(sp)
    80003540:	e44e                	sd	s3,8(sp)
    80003542:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003544:	00005597          	auipc	a1,0x5
    80003548:	06c58593          	addi	a1,a1,108 # 800085b0 <syscalls+0x158>
    8000354c:	0001c517          	auipc	a0,0x1c
    80003550:	46c50513          	addi	a0,a0,1132 # 8001f9b8 <itable>
    80003554:	ffffd097          	auipc	ra,0xffffd
    80003558:	664080e7          	jalr	1636(ra) # 80000bb8 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000355c:	0001c497          	auipc	s1,0x1c
    80003560:	48448493          	addi	s1,s1,1156 # 8001f9e0 <itable+0x28>
    80003564:	0001e997          	auipc	s3,0x1e
    80003568:	f0c98993          	addi	s3,s3,-244 # 80021470 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000356c:	00005917          	auipc	s2,0x5
    80003570:	04c90913          	addi	s2,s2,76 # 800085b8 <syscalls+0x160>
    80003574:	85ca                	mv	a1,s2
    80003576:	8526                	mv	a0,s1
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	e12080e7          	jalr	-494(ra) # 8000438a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003580:	08848493          	addi	s1,s1,136
    80003584:	ff3498e3          	bne	s1,s3,80003574 <iinit+0x3e>
}
    80003588:	70a2                	ld	ra,40(sp)
    8000358a:	7402                	ld	s0,32(sp)
    8000358c:	64e2                	ld	s1,24(sp)
    8000358e:	6942                	ld	s2,16(sp)
    80003590:	69a2                	ld	s3,8(sp)
    80003592:	6145                	addi	sp,sp,48
    80003594:	8082                	ret

0000000080003596 <ialloc>:
{
    80003596:	7139                	addi	sp,sp,-64
    80003598:	fc06                	sd	ra,56(sp)
    8000359a:	f822                	sd	s0,48(sp)
    8000359c:	f426                	sd	s1,40(sp)
    8000359e:	f04a                	sd	s2,32(sp)
    800035a0:	ec4e                	sd	s3,24(sp)
    800035a2:	e852                	sd	s4,16(sp)
    800035a4:	e456                	sd	s5,8(sp)
    800035a6:	e05a                	sd	s6,0(sp)
    800035a8:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800035aa:	0001c717          	auipc	a4,0x1c
    800035ae:	3fa72703          	lw	a4,1018(a4) # 8001f9a4 <sb+0xc>
    800035b2:	4785                	li	a5,1
    800035b4:	04e7f863          	bgeu	a5,a4,80003604 <ialloc+0x6e>
    800035b8:	8aaa                	mv	s5,a0
    800035ba:	8b2e                	mv	s6,a1
    800035bc:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035be:	0001ca17          	auipc	s4,0x1c
    800035c2:	3daa0a13          	addi	s4,s4,986 # 8001f998 <sb>
    800035c6:	00495593          	srli	a1,s2,0x4
    800035ca:	018a2783          	lw	a5,24(s4)
    800035ce:	9dbd                	addw	a1,a1,a5
    800035d0:	8556                	mv	a0,s5
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	94c080e7          	jalr	-1716(ra) # 80002f1e <bread>
    800035da:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035dc:	05850993          	addi	s3,a0,88
    800035e0:	00f97793          	andi	a5,s2,15
    800035e4:	079a                	slli	a5,a5,0x6
    800035e6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035e8:	00099783          	lh	a5,0(s3)
    800035ec:	cf9d                	beqz	a5,8000362a <ialloc+0x94>
    brelse(bp);
    800035ee:	00000097          	auipc	ra,0x0
    800035f2:	a60080e7          	jalr	-1440(ra) # 8000304e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f6:	0905                	addi	s2,s2,1
    800035f8:	00ca2703          	lw	a4,12(s4)
    800035fc:	0009079b          	sext.w	a5,s2
    80003600:	fce7e3e3          	bltu	a5,a4,800035c6 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003604:	00005517          	auipc	a0,0x5
    80003608:	fbc50513          	addi	a0,a0,-68 # 800085c0 <syscalls+0x168>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	f7e080e7          	jalr	-130(ra) # 8000058a <printf>
  return 0;
    80003614:	4501                	li	a0,0
}
    80003616:	70e2                	ld	ra,56(sp)
    80003618:	7442                	ld	s0,48(sp)
    8000361a:	74a2                	ld	s1,40(sp)
    8000361c:	7902                	ld	s2,32(sp)
    8000361e:	69e2                	ld	s3,24(sp)
    80003620:	6a42                	ld	s4,16(sp)
    80003622:	6aa2                	ld	s5,8(sp)
    80003624:	6b02                	ld	s6,0(sp)
    80003626:	6121                	addi	sp,sp,64
    80003628:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000362a:	04000613          	li	a2,64
    8000362e:	4581                	li	a1,0
    80003630:	854e                	mv	a0,s3
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	712080e7          	jalr	1810(ra) # 80000d44 <memset>
      dip->type = type;
    8000363a:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000363e:	8526                	mv	a0,s1
    80003640:	00001097          	auipc	ra,0x1
    80003644:	c66080e7          	jalr	-922(ra) # 800042a6 <log_write>
      brelse(bp);
    80003648:	8526                	mv	a0,s1
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	a04080e7          	jalr	-1532(ra) # 8000304e <brelse>
      return iget(dev, inum);
    80003652:	0009059b          	sext.w	a1,s2
    80003656:	8556                	mv	a0,s5
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	da2080e7          	jalr	-606(ra) # 800033fa <iget>
    80003660:	bf5d                	j	80003616 <ialloc+0x80>

0000000080003662 <iupdate>:
{
    80003662:	1101                	addi	sp,sp,-32
    80003664:	ec06                	sd	ra,24(sp)
    80003666:	e822                	sd	s0,16(sp)
    80003668:	e426                	sd	s1,8(sp)
    8000366a:	e04a                	sd	s2,0(sp)
    8000366c:	1000                	addi	s0,sp,32
    8000366e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003670:	415c                	lw	a5,4(a0)
    80003672:	0047d79b          	srliw	a5,a5,0x4
    80003676:	0001c597          	auipc	a1,0x1c
    8000367a:	33a5a583          	lw	a1,826(a1) # 8001f9b0 <sb+0x18>
    8000367e:	9dbd                	addw	a1,a1,a5
    80003680:	4108                	lw	a0,0(a0)
    80003682:	00000097          	auipc	ra,0x0
    80003686:	89c080e7          	jalr	-1892(ra) # 80002f1e <bread>
    8000368a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000368c:	05850793          	addi	a5,a0,88
    80003690:	40d8                	lw	a4,4(s1)
    80003692:	8b3d                	andi	a4,a4,15
    80003694:	071a                	slli	a4,a4,0x6
    80003696:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003698:	04449703          	lh	a4,68(s1)
    8000369c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036a0:	04649703          	lh	a4,70(s1)
    800036a4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036a8:	04849703          	lh	a4,72(s1)
    800036ac:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800036b0:	04a49703          	lh	a4,74(s1)
    800036b4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800036b8:	44f8                	lw	a4,76(s1)
    800036ba:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036bc:	03400613          	li	a2,52
    800036c0:	05048593          	addi	a1,s1,80
    800036c4:	00c78513          	addi	a0,a5,12
    800036c8:	ffffd097          	auipc	ra,0xffffd
    800036cc:	6d8080e7          	jalr	1752(ra) # 80000da0 <memmove>
  log_write(bp);
    800036d0:	854a                	mv	a0,s2
    800036d2:	00001097          	auipc	ra,0x1
    800036d6:	bd4080e7          	jalr	-1068(ra) # 800042a6 <log_write>
  brelse(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00000097          	auipc	ra,0x0
    800036e0:	972080e7          	jalr	-1678(ra) # 8000304e <brelse>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	64a2                	ld	s1,8(sp)
    800036ea:	6902                	ld	s2,0(sp)
    800036ec:	6105                	addi	sp,sp,32
    800036ee:	8082                	ret

00000000800036f0 <idup>:
{
    800036f0:	1101                	addi	sp,sp,-32
    800036f2:	ec06                	sd	ra,24(sp)
    800036f4:	e822                	sd	s0,16(sp)
    800036f6:	e426                	sd	s1,8(sp)
    800036f8:	1000                	addi	s0,sp,32
    800036fa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036fc:	0001c517          	auipc	a0,0x1c
    80003700:	2bc50513          	addi	a0,a0,700 # 8001f9b8 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	544080e7          	jalr	1348(ra) # 80000c48 <acquire>
  ip->ref++;
    8000370c:	449c                	lw	a5,8(s1)
    8000370e:	2785                	addiw	a5,a5,1
    80003710:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003712:	0001c517          	auipc	a0,0x1c
    80003716:	2a650513          	addi	a0,a0,678 # 8001f9b8 <itable>
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	5e2080e7          	jalr	1506(ra) # 80000cfc <release>
}
    80003722:	8526                	mv	a0,s1
    80003724:	60e2                	ld	ra,24(sp)
    80003726:	6442                	ld	s0,16(sp)
    80003728:	64a2                	ld	s1,8(sp)
    8000372a:	6105                	addi	sp,sp,32
    8000372c:	8082                	ret

000000008000372e <ilock>:
{
    8000372e:	1101                	addi	sp,sp,-32
    80003730:	ec06                	sd	ra,24(sp)
    80003732:	e822                	sd	s0,16(sp)
    80003734:	e426                	sd	s1,8(sp)
    80003736:	e04a                	sd	s2,0(sp)
    80003738:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000373a:	c115                	beqz	a0,8000375e <ilock+0x30>
    8000373c:	84aa                	mv	s1,a0
    8000373e:	451c                	lw	a5,8(a0)
    80003740:	00f05f63          	blez	a5,8000375e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003744:	0541                	addi	a0,a0,16
    80003746:	00001097          	auipc	ra,0x1
    8000374a:	c7e080e7          	jalr	-898(ra) # 800043c4 <acquiresleep>
  if(ip->valid == 0){
    8000374e:	40bc                	lw	a5,64(s1)
    80003750:	cf99                	beqz	a5,8000376e <ilock+0x40>
}
    80003752:	60e2                	ld	ra,24(sp)
    80003754:	6442                	ld	s0,16(sp)
    80003756:	64a2                	ld	s1,8(sp)
    80003758:	6902                	ld	s2,0(sp)
    8000375a:	6105                	addi	sp,sp,32
    8000375c:	8082                	ret
    panic("ilock");
    8000375e:	00005517          	auipc	a0,0x5
    80003762:	e7a50513          	addi	a0,a0,-390 # 800085d8 <syscalls+0x180>
    80003766:	ffffd097          	auipc	ra,0xffffd
    8000376a:	dda080e7          	jalr	-550(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000376e:	40dc                	lw	a5,4(s1)
    80003770:	0047d79b          	srliw	a5,a5,0x4
    80003774:	0001c597          	auipc	a1,0x1c
    80003778:	23c5a583          	lw	a1,572(a1) # 8001f9b0 <sb+0x18>
    8000377c:	9dbd                	addw	a1,a1,a5
    8000377e:	4088                	lw	a0,0(s1)
    80003780:	fffff097          	auipc	ra,0xfffff
    80003784:	79e080e7          	jalr	1950(ra) # 80002f1e <bread>
    80003788:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000378a:	05850593          	addi	a1,a0,88
    8000378e:	40dc                	lw	a5,4(s1)
    80003790:	8bbd                	andi	a5,a5,15
    80003792:	079a                	slli	a5,a5,0x6
    80003794:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003796:	00059783          	lh	a5,0(a1)
    8000379a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000379e:	00259783          	lh	a5,2(a1)
    800037a2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037a6:	00459783          	lh	a5,4(a1)
    800037aa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ae:	00659783          	lh	a5,6(a1)
    800037b2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037b6:	459c                	lw	a5,8(a1)
    800037b8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037ba:	03400613          	li	a2,52
    800037be:	05b1                	addi	a1,a1,12
    800037c0:	05048513          	addi	a0,s1,80
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	5dc080e7          	jalr	1500(ra) # 80000da0 <memmove>
    brelse(bp);
    800037cc:	854a                	mv	a0,s2
    800037ce:	00000097          	auipc	ra,0x0
    800037d2:	880080e7          	jalr	-1920(ra) # 8000304e <brelse>
    ip->valid = 1;
    800037d6:	4785                	li	a5,1
    800037d8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037da:	04449783          	lh	a5,68(s1)
    800037de:	fbb5                	bnez	a5,80003752 <ilock+0x24>
      panic("ilock: no type");
    800037e0:	00005517          	auipc	a0,0x5
    800037e4:	e0050513          	addi	a0,a0,-512 # 800085e0 <syscalls+0x188>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	d58080e7          	jalr	-680(ra) # 80000540 <panic>

00000000800037f0 <iunlock>:
{
    800037f0:	1101                	addi	sp,sp,-32
    800037f2:	ec06                	sd	ra,24(sp)
    800037f4:	e822                	sd	s0,16(sp)
    800037f6:	e426                	sd	s1,8(sp)
    800037f8:	e04a                	sd	s2,0(sp)
    800037fa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800037fc:	c905                	beqz	a0,8000382c <iunlock+0x3c>
    800037fe:	84aa                	mv	s1,a0
    80003800:	01050913          	addi	s2,a0,16
    80003804:	854a                	mv	a0,s2
    80003806:	00001097          	auipc	ra,0x1
    8000380a:	c58080e7          	jalr	-936(ra) # 8000445e <holdingsleep>
    8000380e:	cd19                	beqz	a0,8000382c <iunlock+0x3c>
    80003810:	449c                	lw	a5,8(s1)
    80003812:	00f05d63          	blez	a5,8000382c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003816:	854a                	mv	a0,s2
    80003818:	00001097          	auipc	ra,0x1
    8000381c:	c02080e7          	jalr	-1022(ra) # 8000441a <releasesleep>
}
    80003820:	60e2                	ld	ra,24(sp)
    80003822:	6442                	ld	s0,16(sp)
    80003824:	64a2                	ld	s1,8(sp)
    80003826:	6902                	ld	s2,0(sp)
    80003828:	6105                	addi	sp,sp,32
    8000382a:	8082                	ret
    panic("iunlock");
    8000382c:	00005517          	auipc	a0,0x5
    80003830:	dc450513          	addi	a0,a0,-572 # 800085f0 <syscalls+0x198>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	d0c080e7          	jalr	-756(ra) # 80000540 <panic>

000000008000383c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000383c:	7179                	addi	sp,sp,-48
    8000383e:	f406                	sd	ra,40(sp)
    80003840:	f022                	sd	s0,32(sp)
    80003842:	ec26                	sd	s1,24(sp)
    80003844:	e84a                	sd	s2,16(sp)
    80003846:	e44e                	sd	s3,8(sp)
    80003848:	e052                	sd	s4,0(sp)
    8000384a:	1800                	addi	s0,sp,48
    8000384c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000384e:	05050493          	addi	s1,a0,80
    80003852:	08050913          	addi	s2,a0,128
    80003856:	a021                	j	8000385e <itrunc+0x22>
    80003858:	0491                	addi	s1,s1,4
    8000385a:	01248d63          	beq	s1,s2,80003874 <itrunc+0x38>
    if(ip->addrs[i]){
    8000385e:	408c                	lw	a1,0(s1)
    80003860:	dde5                	beqz	a1,80003858 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003862:	0009a503          	lw	a0,0(s3)
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	8fc080e7          	jalr	-1796(ra) # 80003162 <bfree>
      ip->addrs[i] = 0;
    8000386e:	0004a023          	sw	zero,0(s1)
    80003872:	b7dd                	j	80003858 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003874:	0809a583          	lw	a1,128(s3)
    80003878:	e185                	bnez	a1,80003898 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000387a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000387e:	854e                	mv	a0,s3
    80003880:	00000097          	auipc	ra,0x0
    80003884:	de2080e7          	jalr	-542(ra) # 80003662 <iupdate>
}
    80003888:	70a2                	ld	ra,40(sp)
    8000388a:	7402                	ld	s0,32(sp)
    8000388c:	64e2                	ld	s1,24(sp)
    8000388e:	6942                	ld	s2,16(sp)
    80003890:	69a2                	ld	s3,8(sp)
    80003892:	6a02                	ld	s4,0(sp)
    80003894:	6145                	addi	sp,sp,48
    80003896:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003898:	0009a503          	lw	a0,0(s3)
    8000389c:	fffff097          	auipc	ra,0xfffff
    800038a0:	682080e7          	jalr	1666(ra) # 80002f1e <bread>
    800038a4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038a6:	05850493          	addi	s1,a0,88
    800038aa:	45850913          	addi	s2,a0,1112
    800038ae:	a021                	j	800038b6 <itrunc+0x7a>
    800038b0:	0491                	addi	s1,s1,4
    800038b2:	01248b63          	beq	s1,s2,800038c8 <itrunc+0x8c>
      if(a[j])
    800038b6:	408c                	lw	a1,0(s1)
    800038b8:	dde5                	beqz	a1,800038b0 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800038ba:	0009a503          	lw	a0,0(s3)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	8a4080e7          	jalr	-1884(ra) # 80003162 <bfree>
    800038c6:	b7ed                	j	800038b0 <itrunc+0x74>
    brelse(bp);
    800038c8:	8552                	mv	a0,s4
    800038ca:	fffff097          	auipc	ra,0xfffff
    800038ce:	784080e7          	jalr	1924(ra) # 8000304e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038d2:	0809a583          	lw	a1,128(s3)
    800038d6:	0009a503          	lw	a0,0(s3)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	888080e7          	jalr	-1912(ra) # 80003162 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038e2:	0809a023          	sw	zero,128(s3)
    800038e6:	bf51                	j	8000387a <itrunc+0x3e>

00000000800038e8 <iput>:
{
    800038e8:	1101                	addi	sp,sp,-32
    800038ea:	ec06                	sd	ra,24(sp)
    800038ec:	e822                	sd	s0,16(sp)
    800038ee:	e426                	sd	s1,8(sp)
    800038f0:	e04a                	sd	s2,0(sp)
    800038f2:	1000                	addi	s0,sp,32
    800038f4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038f6:	0001c517          	auipc	a0,0x1c
    800038fa:	0c250513          	addi	a0,a0,194 # 8001f9b8 <itable>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	34a080e7          	jalr	842(ra) # 80000c48 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003906:	4498                	lw	a4,8(s1)
    80003908:	4785                	li	a5,1
    8000390a:	02f70363          	beq	a4,a5,80003930 <iput+0x48>
  ip->ref--;
    8000390e:	449c                	lw	a5,8(s1)
    80003910:	37fd                	addiw	a5,a5,-1
    80003912:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003914:	0001c517          	auipc	a0,0x1c
    80003918:	0a450513          	addi	a0,a0,164 # 8001f9b8 <itable>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	3e0080e7          	jalr	992(ra) # 80000cfc <release>
}
    80003924:	60e2                	ld	ra,24(sp)
    80003926:	6442                	ld	s0,16(sp)
    80003928:	64a2                	ld	s1,8(sp)
    8000392a:	6902                	ld	s2,0(sp)
    8000392c:	6105                	addi	sp,sp,32
    8000392e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003930:	40bc                	lw	a5,64(s1)
    80003932:	dff1                	beqz	a5,8000390e <iput+0x26>
    80003934:	04a49783          	lh	a5,74(s1)
    80003938:	fbf9                	bnez	a5,8000390e <iput+0x26>
    acquiresleep(&ip->lock);
    8000393a:	01048913          	addi	s2,s1,16
    8000393e:	854a                	mv	a0,s2
    80003940:	00001097          	auipc	ra,0x1
    80003944:	a84080e7          	jalr	-1404(ra) # 800043c4 <acquiresleep>
    release(&itable.lock);
    80003948:	0001c517          	auipc	a0,0x1c
    8000394c:	07050513          	addi	a0,a0,112 # 8001f9b8 <itable>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	3ac080e7          	jalr	940(ra) # 80000cfc <release>
    itrunc(ip);
    80003958:	8526                	mv	a0,s1
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	ee2080e7          	jalr	-286(ra) # 8000383c <itrunc>
    ip->type = 0;
    80003962:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003966:	8526                	mv	a0,s1
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	cfa080e7          	jalr	-774(ra) # 80003662 <iupdate>
    ip->valid = 0;
    80003970:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003974:	854a                	mv	a0,s2
    80003976:	00001097          	auipc	ra,0x1
    8000397a:	aa4080e7          	jalr	-1372(ra) # 8000441a <releasesleep>
    acquire(&itable.lock);
    8000397e:	0001c517          	auipc	a0,0x1c
    80003982:	03a50513          	addi	a0,a0,58 # 8001f9b8 <itable>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	2c2080e7          	jalr	706(ra) # 80000c48 <acquire>
    8000398e:	b741                	j	8000390e <iput+0x26>

0000000080003990 <iunlockput>:
{
    80003990:	1101                	addi	sp,sp,-32
    80003992:	ec06                	sd	ra,24(sp)
    80003994:	e822                	sd	s0,16(sp)
    80003996:	e426                	sd	s1,8(sp)
    80003998:	1000                	addi	s0,sp,32
    8000399a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000399c:	00000097          	auipc	ra,0x0
    800039a0:	e54080e7          	jalr	-428(ra) # 800037f0 <iunlock>
  iput(ip);
    800039a4:	8526                	mv	a0,s1
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	f42080e7          	jalr	-190(ra) # 800038e8 <iput>
}
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	64a2                	ld	s1,8(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret

00000000800039b8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039b8:	1141                	addi	sp,sp,-16
    800039ba:	e422                	sd	s0,8(sp)
    800039bc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039be:	411c                	lw	a5,0(a0)
    800039c0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039c2:	415c                	lw	a5,4(a0)
    800039c4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039c6:	04451783          	lh	a5,68(a0)
    800039ca:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039ce:	04a51783          	lh	a5,74(a0)
    800039d2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039d6:	04c56783          	lwu	a5,76(a0)
    800039da:	e99c                	sd	a5,16(a1)
}
    800039dc:	6422                	ld	s0,8(sp)
    800039de:	0141                	addi	sp,sp,16
    800039e0:	8082                	ret

00000000800039e2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039e2:	457c                	lw	a5,76(a0)
    800039e4:	0ed7e963          	bltu	a5,a3,80003ad6 <readi+0xf4>
{
    800039e8:	7159                	addi	sp,sp,-112
    800039ea:	f486                	sd	ra,104(sp)
    800039ec:	f0a2                	sd	s0,96(sp)
    800039ee:	eca6                	sd	s1,88(sp)
    800039f0:	e8ca                	sd	s2,80(sp)
    800039f2:	e4ce                	sd	s3,72(sp)
    800039f4:	e0d2                	sd	s4,64(sp)
    800039f6:	fc56                	sd	s5,56(sp)
    800039f8:	f85a                	sd	s6,48(sp)
    800039fa:	f45e                	sd	s7,40(sp)
    800039fc:	f062                	sd	s8,32(sp)
    800039fe:	ec66                	sd	s9,24(sp)
    80003a00:	e86a                	sd	s10,16(sp)
    80003a02:	e46e                	sd	s11,8(sp)
    80003a04:	1880                	addi	s0,sp,112
    80003a06:	8b2a                	mv	s6,a0
    80003a08:	8bae                	mv	s7,a1
    80003a0a:	8a32                	mv	s4,a2
    80003a0c:	84b6                	mv	s1,a3
    80003a0e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a10:	9f35                	addw	a4,a4,a3
    return 0;
    80003a12:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a14:	0ad76063          	bltu	a4,a3,80003ab4 <readi+0xd2>
  if(off + n > ip->size)
    80003a18:	00e7f463          	bgeu	a5,a4,80003a20 <readi+0x3e>
    n = ip->size - off;
    80003a1c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a20:	0a0a8963          	beqz	s5,80003ad2 <readi+0xf0>
    80003a24:	4981                	li	s3,0
#if 0
    // Adil: Remove later
    printf("ip->dev; %d\n", ip->dev);
#endif

    m = min(n - tot, BSIZE - off%BSIZE);
    80003a26:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a2a:	5c7d                	li	s8,-1
    80003a2c:	a82d                	j	80003a66 <readi+0x84>
    80003a2e:	020d1d93          	slli	s11,s10,0x20
    80003a32:	020ddd93          	srli	s11,s11,0x20
    80003a36:	05890613          	addi	a2,s2,88
    80003a3a:	86ee                	mv	a3,s11
    80003a3c:	963a                	add	a2,a2,a4
    80003a3e:	85d2                	mv	a1,s4
    80003a40:	855e                	mv	a0,s7
    80003a42:	fffff097          	auipc	ra,0xfffff
    80003a46:	ac0080e7          	jalr	-1344(ra) # 80002502 <either_copyout>
    80003a4a:	05850d63          	beq	a0,s8,80003aa4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a4e:	854a                	mv	a0,s2
    80003a50:	fffff097          	auipc	ra,0xfffff
    80003a54:	5fe080e7          	jalr	1534(ra) # 8000304e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a58:	013d09bb          	addw	s3,s10,s3
    80003a5c:	009d04bb          	addw	s1,s10,s1
    80003a60:	9a6e                	add	s4,s4,s11
    80003a62:	0559f763          	bgeu	s3,s5,80003ab0 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003a66:	00a4d59b          	srliw	a1,s1,0xa
    80003a6a:	855a                	mv	a0,s6
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	8a4080e7          	jalr	-1884(ra) # 80003310 <bmap>
    80003a74:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a78:	cd85                	beqz	a1,80003ab0 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003a7a:	000b2503          	lw	a0,0(s6)
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	4a0080e7          	jalr	1184(ra) # 80002f1e <bread>
    80003a86:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a88:	3ff4f713          	andi	a4,s1,1023
    80003a8c:	40ec87bb          	subw	a5,s9,a4
    80003a90:	413a86bb          	subw	a3,s5,s3
    80003a94:	8d3e                	mv	s10,a5
    80003a96:	2781                	sext.w	a5,a5
    80003a98:	0006861b          	sext.w	a2,a3
    80003a9c:	f8f679e3          	bgeu	a2,a5,80003a2e <readi+0x4c>
    80003aa0:	8d36                	mv	s10,a3
    80003aa2:	b771                	j	80003a2e <readi+0x4c>
      brelse(bp);
    80003aa4:	854a                	mv	a0,s2
    80003aa6:	fffff097          	auipc	ra,0xfffff
    80003aaa:	5a8080e7          	jalr	1448(ra) # 8000304e <brelse>
      tot = -1;
    80003aae:	59fd                	li	s3,-1
  }
  return tot;
    80003ab0:	0009851b          	sext.w	a0,s3
}
    80003ab4:	70a6                	ld	ra,104(sp)
    80003ab6:	7406                	ld	s0,96(sp)
    80003ab8:	64e6                	ld	s1,88(sp)
    80003aba:	6946                	ld	s2,80(sp)
    80003abc:	69a6                	ld	s3,72(sp)
    80003abe:	6a06                	ld	s4,64(sp)
    80003ac0:	7ae2                	ld	s5,56(sp)
    80003ac2:	7b42                	ld	s6,48(sp)
    80003ac4:	7ba2                	ld	s7,40(sp)
    80003ac6:	7c02                	ld	s8,32(sp)
    80003ac8:	6ce2                	ld	s9,24(sp)
    80003aca:	6d42                	ld	s10,16(sp)
    80003acc:	6da2                	ld	s11,8(sp)
    80003ace:	6165                	addi	sp,sp,112
    80003ad0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad2:	89d6                	mv	s3,s5
    80003ad4:	bff1                	j	80003ab0 <readi+0xce>
    return 0;
    80003ad6:	4501                	li	a0,0
}
    80003ad8:	8082                	ret

0000000080003ada <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ada:	457c                	lw	a5,76(a0)
    80003adc:	10d7e863          	bltu	a5,a3,80003bec <writei+0x112>
{
    80003ae0:	7159                	addi	sp,sp,-112
    80003ae2:	f486                	sd	ra,104(sp)
    80003ae4:	f0a2                	sd	s0,96(sp)
    80003ae6:	eca6                	sd	s1,88(sp)
    80003ae8:	e8ca                	sd	s2,80(sp)
    80003aea:	e4ce                	sd	s3,72(sp)
    80003aec:	e0d2                	sd	s4,64(sp)
    80003aee:	fc56                	sd	s5,56(sp)
    80003af0:	f85a                	sd	s6,48(sp)
    80003af2:	f45e                	sd	s7,40(sp)
    80003af4:	f062                	sd	s8,32(sp)
    80003af6:	ec66                	sd	s9,24(sp)
    80003af8:	e86a                	sd	s10,16(sp)
    80003afa:	e46e                	sd	s11,8(sp)
    80003afc:	1880                	addi	s0,sp,112
    80003afe:	8aaa                	mv	s5,a0
    80003b00:	8bae                	mv	s7,a1
    80003b02:	8a32                	mv	s4,a2
    80003b04:	8936                	mv	s2,a3
    80003b06:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b08:	00e687bb          	addw	a5,a3,a4
    80003b0c:	0ed7e263          	bltu	a5,a3,80003bf0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b10:	00043737          	lui	a4,0x43
    80003b14:	0ef76063          	bltu	a4,a5,80003bf4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b18:	0c0b0863          	beqz	s6,80003be8 <writei+0x10e>
    80003b1c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b22:	5c7d                	li	s8,-1
    80003b24:	a091                	j	80003b68 <writei+0x8e>
    80003b26:	020d1d93          	slli	s11,s10,0x20
    80003b2a:	020ddd93          	srli	s11,s11,0x20
    80003b2e:	05848513          	addi	a0,s1,88
    80003b32:	86ee                	mv	a3,s11
    80003b34:	8652                	mv	a2,s4
    80003b36:	85de                	mv	a1,s7
    80003b38:	953a                	add	a0,a0,a4
    80003b3a:	fffff097          	auipc	ra,0xfffff
    80003b3e:	a1e080e7          	jalr	-1506(ra) # 80002558 <either_copyin>
    80003b42:	07850263          	beq	a0,s8,80003ba6 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b46:	8526                	mv	a0,s1
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	75e080e7          	jalr	1886(ra) # 800042a6 <log_write>
    brelse(bp);
    80003b50:	8526                	mv	a0,s1
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	4fc080e7          	jalr	1276(ra) # 8000304e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b5a:	013d09bb          	addw	s3,s10,s3
    80003b5e:	012d093b          	addw	s2,s10,s2
    80003b62:	9a6e                	add	s4,s4,s11
    80003b64:	0569f663          	bgeu	s3,s6,80003bb0 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003b68:	00a9559b          	srliw	a1,s2,0xa
    80003b6c:	8556                	mv	a0,s5
    80003b6e:	fffff097          	auipc	ra,0xfffff
    80003b72:	7a2080e7          	jalr	1954(ra) # 80003310 <bmap>
    80003b76:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b7a:	c99d                	beqz	a1,80003bb0 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003b7c:	000aa503          	lw	a0,0(s5)
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	39e080e7          	jalr	926(ra) # 80002f1e <bread>
    80003b88:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8a:	3ff97713          	andi	a4,s2,1023
    80003b8e:	40ec87bb          	subw	a5,s9,a4
    80003b92:	413b06bb          	subw	a3,s6,s3
    80003b96:	8d3e                	mv	s10,a5
    80003b98:	2781                	sext.w	a5,a5
    80003b9a:	0006861b          	sext.w	a2,a3
    80003b9e:	f8f674e3          	bgeu	a2,a5,80003b26 <writei+0x4c>
    80003ba2:	8d36                	mv	s10,a3
    80003ba4:	b749                	j	80003b26 <writei+0x4c>
      brelse(bp);
    80003ba6:	8526                	mv	a0,s1
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	4a6080e7          	jalr	1190(ra) # 8000304e <brelse>
  }

  if(off > ip->size)
    80003bb0:	04caa783          	lw	a5,76(s5)
    80003bb4:	0127f463          	bgeu	a5,s2,80003bbc <writei+0xe2>
    ip->size = off;
    80003bb8:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bbc:	8556                	mv	a0,s5
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	aa4080e7          	jalr	-1372(ra) # 80003662 <iupdate>

  return tot;
    80003bc6:	0009851b          	sext.w	a0,s3
}
    80003bca:	70a6                	ld	ra,104(sp)
    80003bcc:	7406                	ld	s0,96(sp)
    80003bce:	64e6                	ld	s1,88(sp)
    80003bd0:	6946                	ld	s2,80(sp)
    80003bd2:	69a6                	ld	s3,72(sp)
    80003bd4:	6a06                	ld	s4,64(sp)
    80003bd6:	7ae2                	ld	s5,56(sp)
    80003bd8:	7b42                	ld	s6,48(sp)
    80003bda:	7ba2                	ld	s7,40(sp)
    80003bdc:	7c02                	ld	s8,32(sp)
    80003bde:	6ce2                	ld	s9,24(sp)
    80003be0:	6d42                	ld	s10,16(sp)
    80003be2:	6da2                	ld	s11,8(sp)
    80003be4:	6165                	addi	sp,sp,112
    80003be6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003be8:	89da                	mv	s3,s6
    80003bea:	bfc9                	j	80003bbc <writei+0xe2>
    return -1;
    80003bec:	557d                	li	a0,-1
}
    80003bee:	8082                	ret
    return -1;
    80003bf0:	557d                	li	a0,-1
    80003bf2:	bfe1                	j	80003bca <writei+0xf0>
    return -1;
    80003bf4:	557d                	li	a0,-1
    80003bf6:	bfd1                	j	80003bca <writei+0xf0>

0000000080003bf8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003bf8:	1141                	addi	sp,sp,-16
    80003bfa:	e406                	sd	ra,8(sp)
    80003bfc:	e022                	sd	s0,0(sp)
    80003bfe:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c00:	4639                	li	a2,14
    80003c02:	ffffd097          	auipc	ra,0xffffd
    80003c06:	212080e7          	jalr	530(ra) # 80000e14 <strncmp>
}
    80003c0a:	60a2                	ld	ra,8(sp)
    80003c0c:	6402                	ld	s0,0(sp)
    80003c0e:	0141                	addi	sp,sp,16
    80003c10:	8082                	ret

0000000080003c12 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c12:	7139                	addi	sp,sp,-64
    80003c14:	fc06                	sd	ra,56(sp)
    80003c16:	f822                	sd	s0,48(sp)
    80003c18:	f426                	sd	s1,40(sp)
    80003c1a:	f04a                	sd	s2,32(sp)
    80003c1c:	ec4e                	sd	s3,24(sp)
    80003c1e:	e852                	sd	s4,16(sp)
    80003c20:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c22:	04451703          	lh	a4,68(a0)
    80003c26:	4785                	li	a5,1
    80003c28:	00f71a63          	bne	a4,a5,80003c3c <dirlookup+0x2a>
    80003c2c:	892a                	mv	s2,a0
    80003c2e:	89ae                	mv	s3,a1
    80003c30:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c32:	457c                	lw	a5,76(a0)
    80003c34:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c36:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c38:	e79d                	bnez	a5,80003c66 <dirlookup+0x54>
    80003c3a:	a8a5                	j	80003cb2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c3c:	00005517          	auipc	a0,0x5
    80003c40:	9bc50513          	addi	a0,a0,-1604 # 800085f8 <syscalls+0x1a0>
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	8fc080e7          	jalr	-1796(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c4c:	00005517          	auipc	a0,0x5
    80003c50:	9c450513          	addi	a0,a0,-1596 # 80008610 <syscalls+0x1b8>
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	8ec080e7          	jalr	-1812(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c5c:	24c1                	addiw	s1,s1,16
    80003c5e:	04c92783          	lw	a5,76(s2)
    80003c62:	04f4f763          	bgeu	s1,a5,80003cb0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c66:	4741                	li	a4,16
    80003c68:	86a6                	mv	a3,s1
    80003c6a:	fc040613          	addi	a2,s0,-64
    80003c6e:	4581                	li	a1,0
    80003c70:	854a                	mv	a0,s2
    80003c72:	00000097          	auipc	ra,0x0
    80003c76:	d70080e7          	jalr	-656(ra) # 800039e2 <readi>
    80003c7a:	47c1                	li	a5,16
    80003c7c:	fcf518e3          	bne	a0,a5,80003c4c <dirlookup+0x3a>
    if(de.inum == 0)
    80003c80:	fc045783          	lhu	a5,-64(s0)
    80003c84:	dfe1                	beqz	a5,80003c5c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c86:	fc240593          	addi	a1,s0,-62
    80003c8a:	854e                	mv	a0,s3
    80003c8c:	00000097          	auipc	ra,0x0
    80003c90:	f6c080e7          	jalr	-148(ra) # 80003bf8 <namecmp>
    80003c94:	f561                	bnez	a0,80003c5c <dirlookup+0x4a>
      if(poff)
    80003c96:	000a0463          	beqz	s4,80003c9e <dirlookup+0x8c>
        *poff = off;
    80003c9a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003c9e:	fc045583          	lhu	a1,-64(s0)
    80003ca2:	00092503          	lw	a0,0(s2)
    80003ca6:	fffff097          	auipc	ra,0xfffff
    80003caa:	754080e7          	jalr	1876(ra) # 800033fa <iget>
    80003cae:	a011                	j	80003cb2 <dirlookup+0xa0>
  return 0;
    80003cb0:	4501                	li	a0,0
}
    80003cb2:	70e2                	ld	ra,56(sp)
    80003cb4:	7442                	ld	s0,48(sp)
    80003cb6:	74a2                	ld	s1,40(sp)
    80003cb8:	7902                	ld	s2,32(sp)
    80003cba:	69e2                	ld	s3,24(sp)
    80003cbc:	6a42                	ld	s4,16(sp)
    80003cbe:	6121                	addi	sp,sp,64
    80003cc0:	8082                	ret

0000000080003cc2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cc2:	711d                	addi	sp,sp,-96
    80003cc4:	ec86                	sd	ra,88(sp)
    80003cc6:	e8a2                	sd	s0,80(sp)
    80003cc8:	e4a6                	sd	s1,72(sp)
    80003cca:	e0ca                	sd	s2,64(sp)
    80003ccc:	fc4e                	sd	s3,56(sp)
    80003cce:	f852                	sd	s4,48(sp)
    80003cd0:	f456                	sd	s5,40(sp)
    80003cd2:	f05a                	sd	s6,32(sp)
    80003cd4:	ec5e                	sd	s7,24(sp)
    80003cd6:	e862                	sd	s8,16(sp)
    80003cd8:	e466                	sd	s9,8(sp)
    80003cda:	1080                	addi	s0,sp,96
    80003cdc:	84aa                	mv	s1,a0
    80003cde:	8b2e                	mv	s6,a1
    80003ce0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ce2:	00054703          	lbu	a4,0(a0)
    80003ce6:	02f00793          	li	a5,47
    80003cea:	02f70263          	beq	a4,a5,80003d0e <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cee:	ffffe097          	auipc	ra,0xffffe
    80003cf2:	d36080e7          	jalr	-714(ra) # 80001a24 <myproc>
    80003cf6:	15053503          	ld	a0,336(a0)
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	9f6080e7          	jalr	-1546(ra) # 800036f0 <idup>
    80003d02:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d04:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d08:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d0a:	4b85                	li	s7,1
    80003d0c:	a875                	j	80003dc8 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80003d0e:	4585                	li	a1,1
    80003d10:	4505                	li	a0,1
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	6e8080e7          	jalr	1768(ra) # 800033fa <iget>
    80003d1a:	8a2a                	mv	s4,a0
    80003d1c:	b7e5                	j	80003d04 <namex+0x42>
      iunlockput(ip);
    80003d1e:	8552                	mv	a0,s4
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	c70080e7          	jalr	-912(ra) # 80003990 <iunlockput>
      return 0;
    80003d28:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d2a:	8552                	mv	a0,s4
    80003d2c:	60e6                	ld	ra,88(sp)
    80003d2e:	6446                	ld	s0,80(sp)
    80003d30:	64a6                	ld	s1,72(sp)
    80003d32:	6906                	ld	s2,64(sp)
    80003d34:	79e2                	ld	s3,56(sp)
    80003d36:	7a42                	ld	s4,48(sp)
    80003d38:	7aa2                	ld	s5,40(sp)
    80003d3a:	7b02                	ld	s6,32(sp)
    80003d3c:	6be2                	ld	s7,24(sp)
    80003d3e:	6c42                	ld	s8,16(sp)
    80003d40:	6ca2                	ld	s9,8(sp)
    80003d42:	6125                	addi	sp,sp,96
    80003d44:	8082                	ret
      iunlock(ip);
    80003d46:	8552                	mv	a0,s4
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	aa8080e7          	jalr	-1368(ra) # 800037f0 <iunlock>
      return ip;
    80003d50:	bfe9                	j	80003d2a <namex+0x68>
      iunlockput(ip);
    80003d52:	8552                	mv	a0,s4
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	c3c080e7          	jalr	-964(ra) # 80003990 <iunlockput>
      return 0;
    80003d5c:	8a4e                	mv	s4,s3
    80003d5e:	b7f1                	j	80003d2a <namex+0x68>
  len = path - s;
    80003d60:	40998633          	sub	a2,s3,s1
    80003d64:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003d68:	099c5863          	bge	s8,s9,80003df8 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80003d6c:	4639                	li	a2,14
    80003d6e:	85a6                	mv	a1,s1
    80003d70:	8556                	mv	a0,s5
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	02e080e7          	jalr	46(ra) # 80000da0 <memmove>
    80003d7a:	84ce                	mv	s1,s3
  while(*path == '/')
    80003d7c:	0004c783          	lbu	a5,0(s1)
    80003d80:	01279763          	bne	a5,s2,80003d8e <namex+0xcc>
    path++;
    80003d84:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d86:	0004c783          	lbu	a5,0(s1)
    80003d8a:	ff278de3          	beq	a5,s2,80003d84 <namex+0xc2>
    ilock(ip);
    80003d8e:	8552                	mv	a0,s4
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	99e080e7          	jalr	-1634(ra) # 8000372e <ilock>
    if(ip->type != T_DIR){
    80003d98:	044a1783          	lh	a5,68(s4)
    80003d9c:	f97791e3          	bne	a5,s7,80003d1e <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80003da0:	000b0563          	beqz	s6,80003daa <namex+0xe8>
    80003da4:	0004c783          	lbu	a5,0(s1)
    80003da8:	dfd9                	beqz	a5,80003d46 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003daa:	4601                	li	a2,0
    80003dac:	85d6                	mv	a1,s5
    80003dae:	8552                	mv	a0,s4
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	e62080e7          	jalr	-414(ra) # 80003c12 <dirlookup>
    80003db8:	89aa                	mv	s3,a0
    80003dba:	dd41                	beqz	a0,80003d52 <namex+0x90>
    iunlockput(ip);
    80003dbc:	8552                	mv	a0,s4
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	bd2080e7          	jalr	-1070(ra) # 80003990 <iunlockput>
    ip = next;
    80003dc6:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003dc8:	0004c783          	lbu	a5,0(s1)
    80003dcc:	01279763          	bne	a5,s2,80003dda <namex+0x118>
    path++;
    80003dd0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	ff278de3          	beq	a5,s2,80003dd0 <namex+0x10e>
  if(*path == 0)
    80003dda:	cb9d                	beqz	a5,80003e10 <namex+0x14e>
  while(*path != '/' && *path != 0)
    80003ddc:	0004c783          	lbu	a5,0(s1)
    80003de0:	89a6                	mv	s3,s1
  len = path - s;
    80003de2:	4c81                	li	s9,0
    80003de4:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003de6:	01278963          	beq	a5,s2,80003df8 <namex+0x136>
    80003dea:	dbbd                	beqz	a5,80003d60 <namex+0x9e>
    path++;
    80003dec:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003dee:	0009c783          	lbu	a5,0(s3)
    80003df2:	ff279ce3          	bne	a5,s2,80003dea <namex+0x128>
    80003df6:	b7ad                	j	80003d60 <namex+0x9e>
    memmove(name, s, len);
    80003df8:	2601                	sext.w	a2,a2
    80003dfa:	85a6                	mv	a1,s1
    80003dfc:	8556                	mv	a0,s5
    80003dfe:	ffffd097          	auipc	ra,0xffffd
    80003e02:	fa2080e7          	jalr	-94(ra) # 80000da0 <memmove>
    name[len] = 0;
    80003e06:	9cd6                	add	s9,s9,s5
    80003e08:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003e0c:	84ce                	mv	s1,s3
    80003e0e:	b7bd                	j	80003d7c <namex+0xba>
  if(nameiparent){
    80003e10:	f00b0de3          	beqz	s6,80003d2a <namex+0x68>
    iput(ip);
    80003e14:	8552                	mv	a0,s4
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	ad2080e7          	jalr	-1326(ra) # 800038e8 <iput>
    return 0;
    80003e1e:	4a01                	li	s4,0
    80003e20:	b729                	j	80003d2a <namex+0x68>

0000000080003e22 <dirlink>:
{
    80003e22:	7139                	addi	sp,sp,-64
    80003e24:	fc06                	sd	ra,56(sp)
    80003e26:	f822                	sd	s0,48(sp)
    80003e28:	f426                	sd	s1,40(sp)
    80003e2a:	f04a                	sd	s2,32(sp)
    80003e2c:	ec4e                	sd	s3,24(sp)
    80003e2e:	e852                	sd	s4,16(sp)
    80003e30:	0080                	addi	s0,sp,64
    80003e32:	892a                	mv	s2,a0
    80003e34:	8a2e                	mv	s4,a1
    80003e36:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e38:	4601                	li	a2,0
    80003e3a:	00000097          	auipc	ra,0x0
    80003e3e:	dd8080e7          	jalr	-552(ra) # 80003c12 <dirlookup>
    80003e42:	e93d                	bnez	a0,80003eb8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e44:	04c92483          	lw	s1,76(s2)
    80003e48:	c49d                	beqz	s1,80003e76 <dirlink+0x54>
    80003e4a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e4c:	4741                	li	a4,16
    80003e4e:	86a6                	mv	a3,s1
    80003e50:	fc040613          	addi	a2,s0,-64
    80003e54:	4581                	li	a1,0
    80003e56:	854a                	mv	a0,s2
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	b8a080e7          	jalr	-1142(ra) # 800039e2 <readi>
    80003e60:	47c1                	li	a5,16
    80003e62:	06f51163          	bne	a0,a5,80003ec4 <dirlink+0xa2>
    if(de.inum == 0)
    80003e66:	fc045783          	lhu	a5,-64(s0)
    80003e6a:	c791                	beqz	a5,80003e76 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e6c:	24c1                	addiw	s1,s1,16
    80003e6e:	04c92783          	lw	a5,76(s2)
    80003e72:	fcf4ede3          	bltu	s1,a5,80003e4c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e76:	4639                	li	a2,14
    80003e78:	85d2                	mv	a1,s4
    80003e7a:	fc240513          	addi	a0,s0,-62
    80003e7e:	ffffd097          	auipc	ra,0xffffd
    80003e82:	fd2080e7          	jalr	-46(ra) # 80000e50 <strncpy>
  de.inum = inum;
    80003e86:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8a:	4741                	li	a4,16
    80003e8c:	86a6                	mv	a3,s1
    80003e8e:	fc040613          	addi	a2,s0,-64
    80003e92:	4581                	li	a1,0
    80003e94:	854a                	mv	a0,s2
    80003e96:	00000097          	auipc	ra,0x0
    80003e9a:	c44080e7          	jalr	-956(ra) # 80003ada <writei>
    80003e9e:	1541                	addi	a0,a0,-16
    80003ea0:	00a03533          	snez	a0,a0
    80003ea4:	40a00533          	neg	a0,a0
}
    80003ea8:	70e2                	ld	ra,56(sp)
    80003eaa:	7442                	ld	s0,48(sp)
    80003eac:	74a2                	ld	s1,40(sp)
    80003eae:	7902                	ld	s2,32(sp)
    80003eb0:	69e2                	ld	s3,24(sp)
    80003eb2:	6a42                	ld	s4,16(sp)
    80003eb4:	6121                	addi	sp,sp,64
    80003eb6:	8082                	ret
    iput(ip);
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	a30080e7          	jalr	-1488(ra) # 800038e8 <iput>
    return -1;
    80003ec0:	557d                	li	a0,-1
    80003ec2:	b7dd                	j	80003ea8 <dirlink+0x86>
      panic("dirlink read");
    80003ec4:	00004517          	auipc	a0,0x4
    80003ec8:	75c50513          	addi	a0,a0,1884 # 80008620 <syscalls+0x1c8>
    80003ecc:	ffffc097          	auipc	ra,0xffffc
    80003ed0:	674080e7          	jalr	1652(ra) # 80000540 <panic>

0000000080003ed4 <namei>:

struct inode*
namei(char *path)
{
    80003ed4:	1101                	addi	sp,sp,-32
    80003ed6:	ec06                	sd	ra,24(sp)
    80003ed8:	e822                	sd	s0,16(sp)
    80003eda:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003edc:	fe040613          	addi	a2,s0,-32
    80003ee0:	4581                	li	a1,0
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	de0080e7          	jalr	-544(ra) # 80003cc2 <namex>
}
    80003eea:	60e2                	ld	ra,24(sp)
    80003eec:	6442                	ld	s0,16(sp)
    80003eee:	6105                	addi	sp,sp,32
    80003ef0:	8082                	ret

0000000080003ef2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ef2:	1141                	addi	sp,sp,-16
    80003ef4:	e406                	sd	ra,8(sp)
    80003ef6:	e022                	sd	s0,0(sp)
    80003ef8:	0800                	addi	s0,sp,16
    80003efa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003efc:	4585                	li	a1,1
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	dc4080e7          	jalr	-572(ra) # 80003cc2 <namex>
}
    80003f06:	60a2                	ld	ra,8(sp)
    80003f08:	6402                	ld	s0,0(sp)
    80003f0a:	0141                	addi	sp,sp,16
    80003f0c:	8082                	ret

0000000080003f0e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f0e:	1101                	addi	sp,sp,-32
    80003f10:	ec06                	sd	ra,24(sp)
    80003f12:	e822                	sd	s0,16(sp)
    80003f14:	e426                	sd	s1,8(sp)
    80003f16:	e04a                	sd	s2,0(sp)
    80003f18:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f1a:	0001d917          	auipc	s2,0x1d
    80003f1e:	54690913          	addi	s2,s2,1350 # 80021460 <log>
    80003f22:	01892583          	lw	a1,24(s2)
    80003f26:	02892503          	lw	a0,40(s2)
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	ff4080e7          	jalr	-12(ra) # 80002f1e <bread>
    80003f32:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f34:	02c92603          	lw	a2,44(s2)
    80003f38:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f3a:	00c05f63          	blez	a2,80003f58 <write_head+0x4a>
    80003f3e:	0001d717          	auipc	a4,0x1d
    80003f42:	55270713          	addi	a4,a4,1362 # 80021490 <log+0x30>
    80003f46:	87aa                	mv	a5,a0
    80003f48:	060a                	slli	a2,a2,0x2
    80003f4a:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003f4c:	4314                	lw	a3,0(a4)
    80003f4e:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003f50:	0711                	addi	a4,a4,4
    80003f52:	0791                	addi	a5,a5,4
    80003f54:	fec79ce3          	bne	a5,a2,80003f4c <write_head+0x3e>
  }
  bwrite(buf);
    80003f58:	8526                	mv	a0,s1
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	0b6080e7          	jalr	182(ra) # 80003010 <bwrite>
  brelse(buf);
    80003f62:	8526                	mv	a0,s1
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	0ea080e7          	jalr	234(ra) # 8000304e <brelse>
}
    80003f6c:	60e2                	ld	ra,24(sp)
    80003f6e:	6442                	ld	s0,16(sp)
    80003f70:	64a2                	ld	s1,8(sp)
    80003f72:	6902                	ld	s2,0(sp)
    80003f74:	6105                	addi	sp,sp,32
    80003f76:	8082                	ret

0000000080003f78 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003f78:	0001d797          	auipc	a5,0x1d
    80003f7c:	5147a783          	lw	a5,1300(a5) # 8002148c <log+0x2c>
    80003f80:	0af05d63          	blez	a5,8000403a <install_trans+0xc2>
{
    80003f84:	7139                	addi	sp,sp,-64
    80003f86:	fc06                	sd	ra,56(sp)
    80003f88:	f822                	sd	s0,48(sp)
    80003f8a:	f426                	sd	s1,40(sp)
    80003f8c:	f04a                	sd	s2,32(sp)
    80003f8e:	ec4e                	sd	s3,24(sp)
    80003f90:	e852                	sd	s4,16(sp)
    80003f92:	e456                	sd	s5,8(sp)
    80003f94:	e05a                	sd	s6,0(sp)
    80003f96:	0080                	addi	s0,sp,64
    80003f98:	8b2a                	mv	s6,a0
    80003f9a:	0001da97          	auipc	s5,0x1d
    80003f9e:	4f6a8a93          	addi	s5,s5,1270 # 80021490 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fa4:	0001d997          	auipc	s3,0x1d
    80003fa8:	4bc98993          	addi	s3,s3,1212 # 80021460 <log>
    80003fac:	a00d                	j	80003fce <install_trans+0x56>
    brelse(lbuf);
    80003fae:	854a                	mv	a0,s2
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	09e080e7          	jalr	158(ra) # 8000304e <brelse>
    brelse(dbuf);
    80003fb8:	8526                	mv	a0,s1
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	094080e7          	jalr	148(ra) # 8000304e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc2:	2a05                	addiw	s4,s4,1
    80003fc4:	0a91                	addi	s5,s5,4
    80003fc6:	02c9a783          	lw	a5,44(s3)
    80003fca:	04fa5e63          	bge	s4,a5,80004026 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fce:	0189a583          	lw	a1,24(s3)
    80003fd2:	014585bb          	addw	a1,a1,s4
    80003fd6:	2585                	addiw	a1,a1,1
    80003fd8:	0289a503          	lw	a0,40(s3)
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	f42080e7          	jalr	-190(ra) # 80002f1e <bread>
    80003fe4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fe6:	000aa583          	lw	a1,0(s5)
    80003fea:	0289a503          	lw	a0,40(s3)
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	f30080e7          	jalr	-208(ra) # 80002f1e <bread>
    80003ff6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ff8:	40000613          	li	a2,1024
    80003ffc:	05890593          	addi	a1,s2,88
    80004000:	05850513          	addi	a0,a0,88
    80004004:	ffffd097          	auipc	ra,0xffffd
    80004008:	d9c080e7          	jalr	-612(ra) # 80000da0 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000400c:	8526                	mv	a0,s1
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	002080e7          	jalr	2(ra) # 80003010 <bwrite>
    if(recovering == 0)
    80004016:	f80b1ce3          	bnez	s6,80003fae <install_trans+0x36>
      bunpin(dbuf);
    8000401a:	8526                	mv	a0,s1
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	10a080e7          	jalr	266(ra) # 80003126 <bunpin>
    80004024:	b769                	j	80003fae <install_trans+0x36>
}
    80004026:	70e2                	ld	ra,56(sp)
    80004028:	7442                	ld	s0,48(sp)
    8000402a:	74a2                	ld	s1,40(sp)
    8000402c:	7902                	ld	s2,32(sp)
    8000402e:	69e2                	ld	s3,24(sp)
    80004030:	6a42                	ld	s4,16(sp)
    80004032:	6aa2                	ld	s5,8(sp)
    80004034:	6b02                	ld	s6,0(sp)
    80004036:	6121                	addi	sp,sp,64
    80004038:	8082                	ret
    8000403a:	8082                	ret

000000008000403c <initlog>:
{
    8000403c:	7179                	addi	sp,sp,-48
    8000403e:	f406                	sd	ra,40(sp)
    80004040:	f022                	sd	s0,32(sp)
    80004042:	ec26                	sd	s1,24(sp)
    80004044:	e84a                	sd	s2,16(sp)
    80004046:	e44e                	sd	s3,8(sp)
    80004048:	1800                	addi	s0,sp,48
    8000404a:	892a                	mv	s2,a0
    8000404c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000404e:	0001d497          	auipc	s1,0x1d
    80004052:	41248493          	addi	s1,s1,1042 # 80021460 <log>
    80004056:	00004597          	auipc	a1,0x4
    8000405a:	5da58593          	addi	a1,a1,1498 # 80008630 <syscalls+0x1d8>
    8000405e:	8526                	mv	a0,s1
    80004060:	ffffd097          	auipc	ra,0xffffd
    80004064:	b58080e7          	jalr	-1192(ra) # 80000bb8 <initlock>
  log.start = sb->logstart;
    80004068:	0149a583          	lw	a1,20(s3)
    8000406c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000406e:	0109a783          	lw	a5,16(s3)
    80004072:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004074:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004078:	854a                	mv	a0,s2
    8000407a:	fffff097          	auipc	ra,0xfffff
    8000407e:	ea4080e7          	jalr	-348(ra) # 80002f1e <bread>
  log.lh.n = lh->n;
    80004082:	4d30                	lw	a2,88(a0)
    80004084:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004086:	00c05f63          	blez	a2,800040a4 <initlog+0x68>
    8000408a:	87aa                	mv	a5,a0
    8000408c:	0001d717          	auipc	a4,0x1d
    80004090:	40470713          	addi	a4,a4,1028 # 80021490 <log+0x30>
    80004094:	060a                	slli	a2,a2,0x2
    80004096:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004098:	4ff4                	lw	a3,92(a5)
    8000409a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000409c:	0791                	addi	a5,a5,4
    8000409e:	0711                	addi	a4,a4,4
    800040a0:	fec79ce3          	bne	a5,a2,80004098 <initlog+0x5c>
  brelse(buf);
    800040a4:	fffff097          	auipc	ra,0xfffff
    800040a8:	faa080e7          	jalr	-86(ra) # 8000304e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800040ac:	4505                	li	a0,1
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	eca080e7          	jalr	-310(ra) # 80003f78 <install_trans>
  log.lh.n = 0;
    800040b6:	0001d797          	auipc	a5,0x1d
    800040ba:	3c07ab23          	sw	zero,982(a5) # 8002148c <log+0x2c>
  write_head(); // clear the log
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	e50080e7          	jalr	-432(ra) # 80003f0e <write_head>
}
    800040c6:	70a2                	ld	ra,40(sp)
    800040c8:	7402                	ld	s0,32(sp)
    800040ca:	64e2                	ld	s1,24(sp)
    800040cc:	6942                	ld	s2,16(sp)
    800040ce:	69a2                	ld	s3,8(sp)
    800040d0:	6145                	addi	sp,sp,48
    800040d2:	8082                	ret

00000000800040d4 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040d4:	1101                	addi	sp,sp,-32
    800040d6:	ec06                	sd	ra,24(sp)
    800040d8:	e822                	sd	s0,16(sp)
    800040da:	e426                	sd	s1,8(sp)
    800040dc:	e04a                	sd	s2,0(sp)
    800040de:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800040e0:	0001d517          	auipc	a0,0x1d
    800040e4:	38050513          	addi	a0,a0,896 # 80021460 <log>
    800040e8:	ffffd097          	auipc	ra,0xffffd
    800040ec:	b60080e7          	jalr	-1184(ra) # 80000c48 <acquire>
  while(1){
    if(log.committing){
    800040f0:	0001d497          	auipc	s1,0x1d
    800040f4:	37048493          	addi	s1,s1,880 # 80021460 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800040f8:	4979                	li	s2,30
    800040fa:	a039                	j	80004108 <begin_op+0x34>
      sleep(&log, &log.lock);
    800040fc:	85a6                	mv	a1,s1
    800040fe:	8526                	mv	a0,s1
    80004100:	ffffe097          	auipc	ra,0xffffe
    80004104:	ffa080e7          	jalr	-6(ra) # 800020fa <sleep>
    if(log.committing){
    80004108:	50dc                	lw	a5,36(s1)
    8000410a:	fbed                	bnez	a5,800040fc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000410c:	5098                	lw	a4,32(s1)
    8000410e:	2705                	addiw	a4,a4,1
    80004110:	0027179b          	slliw	a5,a4,0x2
    80004114:	9fb9                	addw	a5,a5,a4
    80004116:	0017979b          	slliw	a5,a5,0x1
    8000411a:	54d4                	lw	a3,44(s1)
    8000411c:	9fb5                	addw	a5,a5,a3
    8000411e:	00f95963          	bge	s2,a5,80004130 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004122:	85a6                	mv	a1,s1
    80004124:	8526                	mv	a0,s1
    80004126:	ffffe097          	auipc	ra,0xffffe
    8000412a:	fd4080e7          	jalr	-44(ra) # 800020fa <sleep>
    8000412e:	bfe9                	j	80004108 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004130:	0001d517          	auipc	a0,0x1d
    80004134:	33050513          	addi	a0,a0,816 # 80021460 <log>
    80004138:	d118                	sw	a4,32(a0)
      release(&log.lock);
    8000413a:	ffffd097          	auipc	ra,0xffffd
    8000413e:	bc2080e7          	jalr	-1086(ra) # 80000cfc <release>
      break;
    }
  }
}
    80004142:	60e2                	ld	ra,24(sp)
    80004144:	6442                	ld	s0,16(sp)
    80004146:	64a2                	ld	s1,8(sp)
    80004148:	6902                	ld	s2,0(sp)
    8000414a:	6105                	addi	sp,sp,32
    8000414c:	8082                	ret

000000008000414e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000414e:	7139                	addi	sp,sp,-64
    80004150:	fc06                	sd	ra,56(sp)
    80004152:	f822                	sd	s0,48(sp)
    80004154:	f426                	sd	s1,40(sp)
    80004156:	f04a                	sd	s2,32(sp)
    80004158:	ec4e                	sd	s3,24(sp)
    8000415a:	e852                	sd	s4,16(sp)
    8000415c:	e456                	sd	s5,8(sp)
    8000415e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004160:	0001d497          	auipc	s1,0x1d
    80004164:	30048493          	addi	s1,s1,768 # 80021460 <log>
    80004168:	8526                	mv	a0,s1
    8000416a:	ffffd097          	auipc	ra,0xffffd
    8000416e:	ade080e7          	jalr	-1314(ra) # 80000c48 <acquire>
  log.outstanding -= 1;
    80004172:	509c                	lw	a5,32(s1)
    80004174:	37fd                	addiw	a5,a5,-1
    80004176:	0007891b          	sext.w	s2,a5
    8000417a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000417c:	50dc                	lw	a5,36(s1)
    8000417e:	e7b9                	bnez	a5,800041cc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004180:	04091e63          	bnez	s2,800041dc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004184:	0001d497          	auipc	s1,0x1d
    80004188:	2dc48493          	addi	s1,s1,732 # 80021460 <log>
    8000418c:	4785                	li	a5,1
    8000418e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004190:	8526                	mv	a0,s1
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	b6a080e7          	jalr	-1174(ra) # 80000cfc <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000419a:	54dc                	lw	a5,44(s1)
    8000419c:	06f04763          	bgtz	a5,8000420a <end_op+0xbc>
    acquire(&log.lock);
    800041a0:	0001d497          	auipc	s1,0x1d
    800041a4:	2c048493          	addi	s1,s1,704 # 80021460 <log>
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffd097          	auipc	ra,0xffffd
    800041ae:	a9e080e7          	jalr	-1378(ra) # 80000c48 <acquire>
    log.committing = 0;
    800041b2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041b6:	8526                	mv	a0,s1
    800041b8:	ffffe097          	auipc	ra,0xffffe
    800041bc:	fa6080e7          	jalr	-90(ra) # 8000215e <wakeup>
    release(&log.lock);
    800041c0:	8526                	mv	a0,s1
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	b3a080e7          	jalr	-1222(ra) # 80000cfc <release>
}
    800041ca:	a03d                	j	800041f8 <end_op+0xaa>
    panic("log.committing");
    800041cc:	00004517          	auipc	a0,0x4
    800041d0:	46c50513          	addi	a0,a0,1132 # 80008638 <syscalls+0x1e0>
    800041d4:	ffffc097          	auipc	ra,0xffffc
    800041d8:	36c080e7          	jalr	876(ra) # 80000540 <panic>
    wakeup(&log);
    800041dc:	0001d497          	auipc	s1,0x1d
    800041e0:	28448493          	addi	s1,s1,644 # 80021460 <log>
    800041e4:	8526                	mv	a0,s1
    800041e6:	ffffe097          	auipc	ra,0xffffe
    800041ea:	f78080e7          	jalr	-136(ra) # 8000215e <wakeup>
  release(&log.lock);
    800041ee:	8526                	mv	a0,s1
    800041f0:	ffffd097          	auipc	ra,0xffffd
    800041f4:	b0c080e7          	jalr	-1268(ra) # 80000cfc <release>
}
    800041f8:	70e2                	ld	ra,56(sp)
    800041fa:	7442                	ld	s0,48(sp)
    800041fc:	74a2                	ld	s1,40(sp)
    800041fe:	7902                	ld	s2,32(sp)
    80004200:	69e2                	ld	s3,24(sp)
    80004202:	6a42                	ld	s4,16(sp)
    80004204:	6aa2                	ld	s5,8(sp)
    80004206:	6121                	addi	sp,sp,64
    80004208:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000420a:	0001da97          	auipc	s5,0x1d
    8000420e:	286a8a93          	addi	s5,s5,646 # 80021490 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004212:	0001da17          	auipc	s4,0x1d
    80004216:	24ea0a13          	addi	s4,s4,590 # 80021460 <log>
    8000421a:	018a2583          	lw	a1,24(s4)
    8000421e:	012585bb          	addw	a1,a1,s2
    80004222:	2585                	addiw	a1,a1,1
    80004224:	028a2503          	lw	a0,40(s4)
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	cf6080e7          	jalr	-778(ra) # 80002f1e <bread>
    80004230:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004232:	000aa583          	lw	a1,0(s5)
    80004236:	028a2503          	lw	a0,40(s4)
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	ce4080e7          	jalr	-796(ra) # 80002f1e <bread>
    80004242:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004244:	40000613          	li	a2,1024
    80004248:	05850593          	addi	a1,a0,88
    8000424c:	05848513          	addi	a0,s1,88
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	b50080e7          	jalr	-1200(ra) # 80000da0 <memmove>
    bwrite(to);  // write the log
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	db6080e7          	jalr	-586(ra) # 80003010 <bwrite>
    brelse(from);
    80004262:	854e                	mv	a0,s3
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	dea080e7          	jalr	-534(ra) # 8000304e <brelse>
    brelse(to);
    8000426c:	8526                	mv	a0,s1
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	de0080e7          	jalr	-544(ra) # 8000304e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004276:	2905                	addiw	s2,s2,1
    80004278:	0a91                	addi	s5,s5,4
    8000427a:	02ca2783          	lw	a5,44(s4)
    8000427e:	f8f94ee3          	blt	s2,a5,8000421a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004282:	00000097          	auipc	ra,0x0
    80004286:	c8c080e7          	jalr	-884(ra) # 80003f0e <write_head>
    install_trans(0); // Now install writes to home locations
    8000428a:	4501                	li	a0,0
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	cec080e7          	jalr	-788(ra) # 80003f78 <install_trans>
    log.lh.n = 0;
    80004294:	0001d797          	auipc	a5,0x1d
    80004298:	1e07ac23          	sw	zero,504(a5) # 8002148c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	c72080e7          	jalr	-910(ra) # 80003f0e <write_head>
    800042a4:	bdf5                	j	800041a0 <end_op+0x52>

00000000800042a6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042a6:	1101                	addi	sp,sp,-32
    800042a8:	ec06                	sd	ra,24(sp)
    800042aa:	e822                	sd	s0,16(sp)
    800042ac:	e426                	sd	s1,8(sp)
    800042ae:	e04a                	sd	s2,0(sp)
    800042b0:	1000                	addi	s0,sp,32
    800042b2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800042b4:	0001d917          	auipc	s2,0x1d
    800042b8:	1ac90913          	addi	s2,s2,428 # 80021460 <log>
    800042bc:	854a                	mv	a0,s2
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	98a080e7          	jalr	-1654(ra) # 80000c48 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042c6:	02c92603          	lw	a2,44(s2)
    800042ca:	47f5                	li	a5,29
    800042cc:	06c7c563          	blt	a5,a2,80004336 <log_write+0x90>
    800042d0:	0001d797          	auipc	a5,0x1d
    800042d4:	1ac7a783          	lw	a5,428(a5) # 8002147c <log+0x1c>
    800042d8:	37fd                	addiw	a5,a5,-1
    800042da:	04f65e63          	bge	a2,a5,80004336 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042de:	0001d797          	auipc	a5,0x1d
    800042e2:	1a27a783          	lw	a5,418(a5) # 80021480 <log+0x20>
    800042e6:	06f05063          	blez	a5,80004346 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800042ea:	4781                	li	a5,0
    800042ec:	06c05563          	blez	a2,80004356 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042f0:	44cc                	lw	a1,12(s1)
    800042f2:	0001d717          	auipc	a4,0x1d
    800042f6:	19e70713          	addi	a4,a4,414 # 80021490 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800042fa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800042fc:	4314                	lw	a3,0(a4)
    800042fe:	04b68c63          	beq	a3,a1,80004356 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004302:	2785                	addiw	a5,a5,1
    80004304:	0711                	addi	a4,a4,4
    80004306:	fef61be3          	bne	a2,a5,800042fc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000430a:	0621                	addi	a2,a2,8
    8000430c:	060a                	slli	a2,a2,0x2
    8000430e:	0001d797          	auipc	a5,0x1d
    80004312:	15278793          	addi	a5,a5,338 # 80021460 <log>
    80004316:	97b2                	add	a5,a5,a2
    80004318:	44d8                	lw	a4,12(s1)
    8000431a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000431c:	8526                	mv	a0,s1
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	dcc080e7          	jalr	-564(ra) # 800030ea <bpin>
    log.lh.n++;
    80004326:	0001d717          	auipc	a4,0x1d
    8000432a:	13a70713          	addi	a4,a4,314 # 80021460 <log>
    8000432e:	575c                	lw	a5,44(a4)
    80004330:	2785                	addiw	a5,a5,1
    80004332:	d75c                	sw	a5,44(a4)
    80004334:	a82d                	j	8000436e <log_write+0xc8>
    panic("too big a transaction");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	31250513          	addi	a0,a0,786 # 80008648 <syscalls+0x1f0>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	202080e7          	jalr	514(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004346:	00004517          	auipc	a0,0x4
    8000434a:	31a50513          	addi	a0,a0,794 # 80008660 <syscalls+0x208>
    8000434e:	ffffc097          	auipc	ra,0xffffc
    80004352:	1f2080e7          	jalr	498(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004356:	00878693          	addi	a3,a5,8
    8000435a:	068a                	slli	a3,a3,0x2
    8000435c:	0001d717          	auipc	a4,0x1d
    80004360:	10470713          	addi	a4,a4,260 # 80021460 <log>
    80004364:	9736                	add	a4,a4,a3
    80004366:	44d4                	lw	a3,12(s1)
    80004368:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000436a:	faf609e3          	beq	a2,a5,8000431c <log_write+0x76>
  }
  release(&log.lock);
    8000436e:	0001d517          	auipc	a0,0x1d
    80004372:	0f250513          	addi	a0,a0,242 # 80021460 <log>
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	986080e7          	jalr	-1658(ra) # 80000cfc <release>
}
    8000437e:	60e2                	ld	ra,24(sp)
    80004380:	6442                	ld	s0,16(sp)
    80004382:	64a2                	ld	s1,8(sp)
    80004384:	6902                	ld	s2,0(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000438a:	1101                	addi	sp,sp,-32
    8000438c:	ec06                	sd	ra,24(sp)
    8000438e:	e822                	sd	s0,16(sp)
    80004390:	e426                	sd	s1,8(sp)
    80004392:	e04a                	sd	s2,0(sp)
    80004394:	1000                	addi	s0,sp,32
    80004396:	84aa                	mv	s1,a0
    80004398:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000439a:	00004597          	auipc	a1,0x4
    8000439e:	2e658593          	addi	a1,a1,742 # 80008680 <syscalls+0x228>
    800043a2:	0521                	addi	a0,a0,8
    800043a4:	ffffd097          	auipc	ra,0xffffd
    800043a8:	814080e7          	jalr	-2028(ra) # 80000bb8 <initlock>
  lk->name = name;
    800043ac:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043b4:	0204a423          	sw	zero,40(s1)
}
    800043b8:	60e2                	ld	ra,24(sp)
    800043ba:	6442                	ld	s0,16(sp)
    800043bc:	64a2                	ld	s1,8(sp)
    800043be:	6902                	ld	s2,0(sp)
    800043c0:	6105                	addi	sp,sp,32
    800043c2:	8082                	ret

00000000800043c4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043c4:	1101                	addi	sp,sp,-32
    800043c6:	ec06                	sd	ra,24(sp)
    800043c8:	e822                	sd	s0,16(sp)
    800043ca:	e426                	sd	s1,8(sp)
    800043cc:	e04a                	sd	s2,0(sp)
    800043ce:	1000                	addi	s0,sp,32
    800043d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800043d2:	00850913          	addi	s2,a0,8
    800043d6:	854a                	mv	a0,s2
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	870080e7          	jalr	-1936(ra) # 80000c48 <acquire>
  while (lk->locked) {
    800043e0:	409c                	lw	a5,0(s1)
    800043e2:	cb89                	beqz	a5,800043f4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800043e4:	85ca                	mv	a1,s2
    800043e6:	8526                	mv	a0,s1
    800043e8:	ffffe097          	auipc	ra,0xffffe
    800043ec:	d12080e7          	jalr	-750(ra) # 800020fa <sleep>
  while (lk->locked) {
    800043f0:	409c                	lw	a5,0(s1)
    800043f2:	fbed                	bnez	a5,800043e4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800043f4:	4785                	li	a5,1
    800043f6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	62c080e7          	jalr	1580(ra) # 80001a24 <myproc>
    80004400:	591c                	lw	a5,48(a0)
    80004402:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004404:	854a                	mv	a0,s2
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	8f6080e7          	jalr	-1802(ra) # 80000cfc <release>
}
    8000440e:	60e2                	ld	ra,24(sp)
    80004410:	6442                	ld	s0,16(sp)
    80004412:	64a2                	ld	s1,8(sp)
    80004414:	6902                	ld	s2,0(sp)
    80004416:	6105                	addi	sp,sp,32
    80004418:	8082                	ret

000000008000441a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000441a:	1101                	addi	sp,sp,-32
    8000441c:	ec06                	sd	ra,24(sp)
    8000441e:	e822                	sd	s0,16(sp)
    80004420:	e426                	sd	s1,8(sp)
    80004422:	e04a                	sd	s2,0(sp)
    80004424:	1000                	addi	s0,sp,32
    80004426:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004428:	00850913          	addi	s2,a0,8
    8000442c:	854a                	mv	a0,s2
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	81a080e7          	jalr	-2022(ra) # 80000c48 <acquire>
  lk->locked = 0;
    80004436:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000443a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000443e:	8526                	mv	a0,s1
    80004440:	ffffe097          	auipc	ra,0xffffe
    80004444:	d1e080e7          	jalr	-738(ra) # 8000215e <wakeup>
  release(&lk->lk);
    80004448:	854a                	mv	a0,s2
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	8b2080e7          	jalr	-1870(ra) # 80000cfc <release>
}
    80004452:	60e2                	ld	ra,24(sp)
    80004454:	6442                	ld	s0,16(sp)
    80004456:	64a2                	ld	s1,8(sp)
    80004458:	6902                	ld	s2,0(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000445e:	7179                	addi	sp,sp,-48
    80004460:	f406                	sd	ra,40(sp)
    80004462:	f022                	sd	s0,32(sp)
    80004464:	ec26                	sd	s1,24(sp)
    80004466:	e84a                	sd	s2,16(sp)
    80004468:	e44e                	sd	s3,8(sp)
    8000446a:	1800                	addi	s0,sp,48
    8000446c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000446e:	00850913          	addi	s2,a0,8
    80004472:	854a                	mv	a0,s2
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	7d4080e7          	jalr	2004(ra) # 80000c48 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000447c:	409c                	lw	a5,0(s1)
    8000447e:	ef99                	bnez	a5,8000449c <holdingsleep+0x3e>
    80004480:	4481                	li	s1,0
  release(&lk->lk);
    80004482:	854a                	mv	a0,s2
    80004484:	ffffd097          	auipc	ra,0xffffd
    80004488:	878080e7          	jalr	-1928(ra) # 80000cfc <release>
  return r;
}
    8000448c:	8526                	mv	a0,s1
    8000448e:	70a2                	ld	ra,40(sp)
    80004490:	7402                	ld	s0,32(sp)
    80004492:	64e2                	ld	s1,24(sp)
    80004494:	6942                	ld	s2,16(sp)
    80004496:	69a2                	ld	s3,8(sp)
    80004498:	6145                	addi	sp,sp,48
    8000449a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000449c:	0284a983          	lw	s3,40(s1)
    800044a0:	ffffd097          	auipc	ra,0xffffd
    800044a4:	584080e7          	jalr	1412(ra) # 80001a24 <myproc>
    800044a8:	5904                	lw	s1,48(a0)
    800044aa:	413484b3          	sub	s1,s1,s3
    800044ae:	0014b493          	seqz	s1,s1
    800044b2:	bfc1                	j	80004482 <holdingsleep+0x24>

00000000800044b4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044b4:	1141                	addi	sp,sp,-16
    800044b6:	e406                	sd	ra,8(sp)
    800044b8:	e022                	sd	s0,0(sp)
    800044ba:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044bc:	00004597          	auipc	a1,0x4
    800044c0:	1d458593          	addi	a1,a1,468 # 80008690 <syscalls+0x238>
    800044c4:	0001d517          	auipc	a0,0x1d
    800044c8:	0e450513          	addi	a0,a0,228 # 800215a8 <ftable>
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	6ec080e7          	jalr	1772(ra) # 80000bb8 <initlock>
}
    800044d4:	60a2                	ld	ra,8(sp)
    800044d6:	6402                	ld	s0,0(sp)
    800044d8:	0141                	addi	sp,sp,16
    800044da:	8082                	ret

00000000800044dc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800044dc:	1101                	addi	sp,sp,-32
    800044de:	ec06                	sd	ra,24(sp)
    800044e0:	e822                	sd	s0,16(sp)
    800044e2:	e426                	sd	s1,8(sp)
    800044e4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800044e6:	0001d517          	auipc	a0,0x1d
    800044ea:	0c250513          	addi	a0,a0,194 # 800215a8 <ftable>
    800044ee:	ffffc097          	auipc	ra,0xffffc
    800044f2:	75a080e7          	jalr	1882(ra) # 80000c48 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800044f6:	0001d497          	auipc	s1,0x1d
    800044fa:	0ca48493          	addi	s1,s1,202 # 800215c0 <ftable+0x18>
    800044fe:	0001e717          	auipc	a4,0x1e
    80004502:	06270713          	addi	a4,a4,98 # 80022560 <disk>
    if(f->ref == 0){
    80004506:	40dc                	lw	a5,4(s1)
    80004508:	cf99                	beqz	a5,80004526 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000450a:	02848493          	addi	s1,s1,40
    8000450e:	fee49ce3          	bne	s1,a4,80004506 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004512:	0001d517          	auipc	a0,0x1d
    80004516:	09650513          	addi	a0,a0,150 # 800215a8 <ftable>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	7e2080e7          	jalr	2018(ra) # 80000cfc <release>
  return 0;
    80004522:	4481                	li	s1,0
    80004524:	a819                	j	8000453a <filealloc+0x5e>
      f->ref = 1;
    80004526:	4785                	li	a5,1
    80004528:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000452a:	0001d517          	auipc	a0,0x1d
    8000452e:	07e50513          	addi	a0,a0,126 # 800215a8 <ftable>
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	7ca080e7          	jalr	1994(ra) # 80000cfc <release>
}
    8000453a:	8526                	mv	a0,s1
    8000453c:	60e2                	ld	ra,24(sp)
    8000453e:	6442                	ld	s0,16(sp)
    80004540:	64a2                	ld	s1,8(sp)
    80004542:	6105                	addi	sp,sp,32
    80004544:	8082                	ret

0000000080004546 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004546:	1101                	addi	sp,sp,-32
    80004548:	ec06                	sd	ra,24(sp)
    8000454a:	e822                	sd	s0,16(sp)
    8000454c:	e426                	sd	s1,8(sp)
    8000454e:	1000                	addi	s0,sp,32
    80004550:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004552:	0001d517          	auipc	a0,0x1d
    80004556:	05650513          	addi	a0,a0,86 # 800215a8 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	6ee080e7          	jalr	1774(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    80004562:	40dc                	lw	a5,4(s1)
    80004564:	02f05263          	blez	a5,80004588 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004568:	2785                	addiw	a5,a5,1
    8000456a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000456c:	0001d517          	auipc	a0,0x1d
    80004570:	03c50513          	addi	a0,a0,60 # 800215a8 <ftable>
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	788080e7          	jalr	1928(ra) # 80000cfc <release>
  return f;
}
    8000457c:	8526                	mv	a0,s1
    8000457e:	60e2                	ld	ra,24(sp)
    80004580:	6442                	ld	s0,16(sp)
    80004582:	64a2                	ld	s1,8(sp)
    80004584:	6105                	addi	sp,sp,32
    80004586:	8082                	ret
    panic("filedup");
    80004588:	00004517          	auipc	a0,0x4
    8000458c:	11050513          	addi	a0,a0,272 # 80008698 <syscalls+0x240>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	fb0080e7          	jalr	-80(ra) # 80000540 <panic>

0000000080004598 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004598:	7139                	addi	sp,sp,-64
    8000459a:	fc06                	sd	ra,56(sp)
    8000459c:	f822                	sd	s0,48(sp)
    8000459e:	f426                	sd	s1,40(sp)
    800045a0:	f04a                	sd	s2,32(sp)
    800045a2:	ec4e                	sd	s3,24(sp)
    800045a4:	e852                	sd	s4,16(sp)
    800045a6:	e456                	sd	s5,8(sp)
    800045a8:	0080                	addi	s0,sp,64
    800045aa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	ffc50513          	addi	a0,a0,-4 # 800215a8 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	694080e7          	jalr	1684(ra) # 80000c48 <acquire>
  if(f->ref < 1)
    800045bc:	40dc                	lw	a5,4(s1)
    800045be:	06f05163          	blez	a5,80004620 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045c2:	37fd                	addiw	a5,a5,-1
    800045c4:	0007871b          	sext.w	a4,a5
    800045c8:	c0dc                	sw	a5,4(s1)
    800045ca:	06e04363          	bgtz	a4,80004630 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800045ce:	0004a903          	lw	s2,0(s1)
    800045d2:	0094ca83          	lbu	s5,9(s1)
    800045d6:	0104ba03          	ld	s4,16(s1)
    800045da:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800045de:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800045e2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800045e6:	0001d517          	auipc	a0,0x1d
    800045ea:	fc250513          	addi	a0,a0,-62 # 800215a8 <ftable>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	70e080e7          	jalr	1806(ra) # 80000cfc <release>

  if(ff.type == FD_PIPE){
    800045f6:	4785                	li	a5,1
    800045f8:	04f90d63          	beq	s2,a5,80004652 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800045fc:	3979                	addiw	s2,s2,-2
    800045fe:	4785                	li	a5,1
    80004600:	0527e063          	bltu	a5,s2,80004640 <fileclose+0xa8>
    begin_op();
    80004604:	00000097          	auipc	ra,0x0
    80004608:	ad0080e7          	jalr	-1328(ra) # 800040d4 <begin_op>
    iput(ff.ip);
    8000460c:	854e                	mv	a0,s3
    8000460e:	fffff097          	auipc	ra,0xfffff
    80004612:	2da080e7          	jalr	730(ra) # 800038e8 <iput>
    end_op();
    80004616:	00000097          	auipc	ra,0x0
    8000461a:	b38080e7          	jalr	-1224(ra) # 8000414e <end_op>
    8000461e:	a00d                	j	80004640 <fileclose+0xa8>
    panic("fileclose");
    80004620:	00004517          	auipc	a0,0x4
    80004624:	08050513          	addi	a0,a0,128 # 800086a0 <syscalls+0x248>
    80004628:	ffffc097          	auipc	ra,0xffffc
    8000462c:	f18080e7          	jalr	-232(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004630:	0001d517          	auipc	a0,0x1d
    80004634:	f7850513          	addi	a0,a0,-136 # 800215a8 <ftable>
    80004638:	ffffc097          	auipc	ra,0xffffc
    8000463c:	6c4080e7          	jalr	1732(ra) # 80000cfc <release>
  }
}
    80004640:	70e2                	ld	ra,56(sp)
    80004642:	7442                	ld	s0,48(sp)
    80004644:	74a2                	ld	s1,40(sp)
    80004646:	7902                	ld	s2,32(sp)
    80004648:	69e2                	ld	s3,24(sp)
    8000464a:	6a42                	ld	s4,16(sp)
    8000464c:	6aa2                	ld	s5,8(sp)
    8000464e:	6121                	addi	sp,sp,64
    80004650:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004652:	85d6                	mv	a1,s5
    80004654:	8552                	mv	a0,s4
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	348080e7          	jalr	840(ra) # 8000499e <pipeclose>
    8000465e:	b7cd                	j	80004640 <fileclose+0xa8>

0000000080004660 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004660:	715d                	addi	sp,sp,-80
    80004662:	e486                	sd	ra,72(sp)
    80004664:	e0a2                	sd	s0,64(sp)
    80004666:	fc26                	sd	s1,56(sp)
    80004668:	f84a                	sd	s2,48(sp)
    8000466a:	f44e                	sd	s3,40(sp)
    8000466c:	0880                	addi	s0,sp,80
    8000466e:	84aa                	mv	s1,a0
    80004670:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004672:	ffffd097          	auipc	ra,0xffffd
    80004676:	3b2080e7          	jalr	946(ra) # 80001a24 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000467a:	409c                	lw	a5,0(s1)
    8000467c:	37f9                	addiw	a5,a5,-2
    8000467e:	4705                	li	a4,1
    80004680:	04f76763          	bltu	a4,a5,800046ce <filestat+0x6e>
    80004684:	892a                	mv	s2,a0
    ilock(f->ip);
    80004686:	6c88                	ld	a0,24(s1)
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	0a6080e7          	jalr	166(ra) # 8000372e <ilock>
    stati(f->ip, &st);
    80004690:	fb840593          	addi	a1,s0,-72
    80004694:	6c88                	ld	a0,24(s1)
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	322080e7          	jalr	802(ra) # 800039b8 <stati>
    iunlock(f->ip);
    8000469e:	6c88                	ld	a0,24(s1)
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	150080e7          	jalr	336(ra) # 800037f0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046a8:	46e1                	li	a3,24
    800046aa:	fb840613          	addi	a2,s0,-72
    800046ae:	85ce                	mv	a1,s3
    800046b0:	05093503          	ld	a0,80(s2)
    800046b4:	ffffd097          	auipc	ra,0xffffd
    800046b8:	030080e7          	jalr	48(ra) # 800016e4 <copyout>
    800046bc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046c0:	60a6                	ld	ra,72(sp)
    800046c2:	6406                	ld	s0,64(sp)
    800046c4:	74e2                	ld	s1,56(sp)
    800046c6:	7942                	ld	s2,48(sp)
    800046c8:	79a2                	ld	s3,40(sp)
    800046ca:	6161                	addi	sp,sp,80
    800046cc:	8082                	ret
  return -1;
    800046ce:	557d                	li	a0,-1
    800046d0:	bfc5                	j	800046c0 <filestat+0x60>

00000000800046d2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800046d2:	7179                	addi	sp,sp,-48
    800046d4:	f406                	sd	ra,40(sp)
    800046d6:	f022                	sd	s0,32(sp)
    800046d8:	ec26                	sd	s1,24(sp)
    800046da:	e84a                	sd	s2,16(sp)
    800046dc:	e44e                	sd	s3,8(sp)
    800046de:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800046e0:	00854783          	lbu	a5,8(a0)
    800046e4:	c3d5                	beqz	a5,80004788 <fileread+0xb6>
    800046e6:	84aa                	mv	s1,a0
    800046e8:	89ae                	mv	s3,a1
    800046ea:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800046ec:	411c                	lw	a5,0(a0)
    800046ee:	4705                	li	a4,1
    800046f0:	04e78963          	beq	a5,a4,80004742 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800046f4:	470d                	li	a4,3
    800046f6:	04e78d63          	beq	a5,a4,80004750 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800046fa:	4709                	li	a4,2
    800046fc:	06e79e63          	bne	a5,a4,80004778 <fileread+0xa6>
    ilock(f->ip);
    80004700:	6d08                	ld	a0,24(a0)
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	02c080e7          	jalr	44(ra) # 8000372e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000470a:	874a                	mv	a4,s2
    8000470c:	5094                	lw	a3,32(s1)
    8000470e:	864e                	mv	a2,s3
    80004710:	4585                	li	a1,1
    80004712:	6c88                	ld	a0,24(s1)
    80004714:	fffff097          	auipc	ra,0xfffff
    80004718:	2ce080e7          	jalr	718(ra) # 800039e2 <readi>
    8000471c:	892a                	mv	s2,a0
    8000471e:	00a05563          	blez	a0,80004728 <fileread+0x56>
      f->off += r;
    80004722:	509c                	lw	a5,32(s1)
    80004724:	9fa9                	addw	a5,a5,a0
    80004726:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004728:	6c88                	ld	a0,24(s1)
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	0c6080e7          	jalr	198(ra) # 800037f0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004732:	854a                	mv	a0,s2
    80004734:	70a2                	ld	ra,40(sp)
    80004736:	7402                	ld	s0,32(sp)
    80004738:	64e2                	ld	s1,24(sp)
    8000473a:	6942                	ld	s2,16(sp)
    8000473c:	69a2                	ld	s3,8(sp)
    8000473e:	6145                	addi	sp,sp,48
    80004740:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004742:	6908                	ld	a0,16(a0)
    80004744:	00000097          	auipc	ra,0x0
    80004748:	3c2080e7          	jalr	962(ra) # 80004b06 <piperead>
    8000474c:	892a                	mv	s2,a0
    8000474e:	b7d5                	j	80004732 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004750:	02451783          	lh	a5,36(a0)
    80004754:	03079693          	slli	a3,a5,0x30
    80004758:	92c1                	srli	a3,a3,0x30
    8000475a:	4725                	li	a4,9
    8000475c:	02d76863          	bltu	a4,a3,8000478c <fileread+0xba>
    80004760:	0792                	slli	a5,a5,0x4
    80004762:	0001d717          	auipc	a4,0x1d
    80004766:	da670713          	addi	a4,a4,-602 # 80021508 <devsw>
    8000476a:	97ba                	add	a5,a5,a4
    8000476c:	639c                	ld	a5,0(a5)
    8000476e:	c38d                	beqz	a5,80004790 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004770:	4505                	li	a0,1
    80004772:	9782                	jalr	a5
    80004774:	892a                	mv	s2,a0
    80004776:	bf75                	j	80004732 <fileread+0x60>
    panic("fileread");
    80004778:	00004517          	auipc	a0,0x4
    8000477c:	f3850513          	addi	a0,a0,-200 # 800086b0 <syscalls+0x258>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>
    return -1;
    80004788:	597d                	li	s2,-1
    8000478a:	b765                	j	80004732 <fileread+0x60>
      return -1;
    8000478c:	597d                	li	s2,-1
    8000478e:	b755                	j	80004732 <fileread+0x60>
    80004790:	597d                	li	s2,-1
    80004792:	b745                	j	80004732 <fileread+0x60>

0000000080004794 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004794:	00954783          	lbu	a5,9(a0)
    80004798:	10078e63          	beqz	a5,800048b4 <filewrite+0x120>
{
    8000479c:	715d                	addi	sp,sp,-80
    8000479e:	e486                	sd	ra,72(sp)
    800047a0:	e0a2                	sd	s0,64(sp)
    800047a2:	fc26                	sd	s1,56(sp)
    800047a4:	f84a                	sd	s2,48(sp)
    800047a6:	f44e                	sd	s3,40(sp)
    800047a8:	f052                	sd	s4,32(sp)
    800047aa:	ec56                	sd	s5,24(sp)
    800047ac:	e85a                	sd	s6,16(sp)
    800047ae:	e45e                	sd	s7,8(sp)
    800047b0:	e062                	sd	s8,0(sp)
    800047b2:	0880                	addi	s0,sp,80
    800047b4:	892a                	mv	s2,a0
    800047b6:	8b2e                	mv	s6,a1
    800047b8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ba:	411c                	lw	a5,0(a0)
    800047bc:	4705                	li	a4,1
    800047be:	02e78263          	beq	a5,a4,800047e2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c2:	470d                	li	a4,3
    800047c4:	02e78563          	beq	a5,a4,800047ee <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047c8:	4709                	li	a4,2
    800047ca:	0ce79d63          	bne	a5,a4,800048a4 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800047ce:	0ac05b63          	blez	a2,80004884 <filewrite+0xf0>
    int i = 0;
    800047d2:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800047d4:	6b85                	lui	s7,0x1
    800047d6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800047da:	6c05                	lui	s8,0x1
    800047dc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800047e0:	a851                	j	80004874 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800047e2:	6908                	ld	a0,16(a0)
    800047e4:	00000097          	auipc	ra,0x0
    800047e8:	22a080e7          	jalr	554(ra) # 80004a0e <pipewrite>
    800047ec:	a045                	j	8000488c <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800047ee:	02451783          	lh	a5,36(a0)
    800047f2:	03079693          	slli	a3,a5,0x30
    800047f6:	92c1                	srli	a3,a3,0x30
    800047f8:	4725                	li	a4,9
    800047fa:	0ad76f63          	bltu	a4,a3,800048b8 <filewrite+0x124>
    800047fe:	0792                	slli	a5,a5,0x4
    80004800:	0001d717          	auipc	a4,0x1d
    80004804:	d0870713          	addi	a4,a4,-760 # 80021508 <devsw>
    80004808:	97ba                	add	a5,a5,a4
    8000480a:	679c                	ld	a5,8(a5)
    8000480c:	cbc5                	beqz	a5,800048bc <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    8000480e:	4505                	li	a0,1
    80004810:	9782                	jalr	a5
    80004812:	a8ad                	j	8000488c <filewrite+0xf8>
      if(n1 > max)
    80004814:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004818:	00000097          	auipc	ra,0x0
    8000481c:	8bc080e7          	jalr	-1860(ra) # 800040d4 <begin_op>
      ilock(f->ip);
    80004820:	01893503          	ld	a0,24(s2)
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	f0a080e7          	jalr	-246(ra) # 8000372e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000482c:	8756                	mv	a4,s5
    8000482e:	02092683          	lw	a3,32(s2)
    80004832:	01698633          	add	a2,s3,s6
    80004836:	4585                	li	a1,1
    80004838:	01893503          	ld	a0,24(s2)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	29e080e7          	jalr	670(ra) # 80003ada <writei>
    80004844:	84aa                	mv	s1,a0
    80004846:	00a05763          	blez	a0,80004854 <filewrite+0xc0>
        f->off += r;
    8000484a:	02092783          	lw	a5,32(s2)
    8000484e:	9fa9                	addw	a5,a5,a0
    80004850:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004854:	01893503          	ld	a0,24(s2)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	f98080e7          	jalr	-104(ra) # 800037f0 <iunlock>
      end_op();
    80004860:	00000097          	auipc	ra,0x0
    80004864:	8ee080e7          	jalr	-1810(ra) # 8000414e <end_op>

      if(r != n1){
    80004868:	009a9f63          	bne	s5,s1,80004886 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    8000486c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004870:	0149db63          	bge	s3,s4,80004886 <filewrite+0xf2>
      int n1 = n - i;
    80004874:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004878:	0004879b          	sext.w	a5,s1
    8000487c:	f8fbdce3          	bge	s7,a5,80004814 <filewrite+0x80>
    80004880:	84e2                	mv	s1,s8
    80004882:	bf49                	j	80004814 <filewrite+0x80>
    int i = 0;
    80004884:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004886:	033a1d63          	bne	s4,s3,800048c0 <filewrite+0x12c>
    8000488a:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000488c:	60a6                	ld	ra,72(sp)
    8000488e:	6406                	ld	s0,64(sp)
    80004890:	74e2                	ld	s1,56(sp)
    80004892:	7942                	ld	s2,48(sp)
    80004894:	79a2                	ld	s3,40(sp)
    80004896:	7a02                	ld	s4,32(sp)
    80004898:	6ae2                	ld	s5,24(sp)
    8000489a:	6b42                	ld	s6,16(sp)
    8000489c:	6ba2                	ld	s7,8(sp)
    8000489e:	6c02                	ld	s8,0(sp)
    800048a0:	6161                	addi	sp,sp,80
    800048a2:	8082                	ret
    panic("filewrite");
    800048a4:	00004517          	auipc	a0,0x4
    800048a8:	e1c50513          	addi	a0,a0,-484 # 800086c0 <syscalls+0x268>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	c94080e7          	jalr	-876(ra) # 80000540 <panic>
    return -1;
    800048b4:	557d                	li	a0,-1
}
    800048b6:	8082                	ret
      return -1;
    800048b8:	557d                	li	a0,-1
    800048ba:	bfc9                	j	8000488c <filewrite+0xf8>
    800048bc:	557d                	li	a0,-1
    800048be:	b7f9                	j	8000488c <filewrite+0xf8>
    ret = (i == n ? n : -1);
    800048c0:	557d                	li	a0,-1
    800048c2:	b7e9                	j	8000488c <filewrite+0xf8>

00000000800048c4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800048c4:	7179                	addi	sp,sp,-48
    800048c6:	f406                	sd	ra,40(sp)
    800048c8:	f022                	sd	s0,32(sp)
    800048ca:	ec26                	sd	s1,24(sp)
    800048cc:	e84a                	sd	s2,16(sp)
    800048ce:	e44e                	sd	s3,8(sp)
    800048d0:	e052                	sd	s4,0(sp)
    800048d2:	1800                	addi	s0,sp,48
    800048d4:	84aa                	mv	s1,a0
    800048d6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800048d8:	0005b023          	sd	zero,0(a1)
    800048dc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	bfc080e7          	jalr	-1028(ra) # 800044dc <filealloc>
    800048e8:	e088                	sd	a0,0(s1)
    800048ea:	c551                	beqz	a0,80004976 <pipealloc+0xb2>
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	bf0080e7          	jalr	-1040(ra) # 800044dc <filealloc>
    800048f4:	00aa3023          	sd	a0,0(s4)
    800048f8:	c92d                	beqz	a0,8000496a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	25e080e7          	jalr	606(ra) # 80000b58 <kalloc>
    80004902:	892a                	mv	s2,a0
    80004904:	c125                	beqz	a0,80004964 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004906:	4985                	li	s3,1
    80004908:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000490c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004910:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004914:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004918:	00004597          	auipc	a1,0x4
    8000491c:	db858593          	addi	a1,a1,-584 # 800086d0 <syscalls+0x278>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	298080e7          	jalr	664(ra) # 80000bb8 <initlock>
  (*f0)->type = FD_PIPE;
    80004928:	609c                	ld	a5,0(s1)
    8000492a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000492e:	609c                	ld	a5,0(s1)
    80004930:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004934:	609c                	ld	a5,0(s1)
    80004936:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000493a:	609c                	ld	a5,0(s1)
    8000493c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004940:	000a3783          	ld	a5,0(s4)
    80004944:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004948:	000a3783          	ld	a5,0(s4)
    8000494c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004950:	000a3783          	ld	a5,0(s4)
    80004954:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004958:	000a3783          	ld	a5,0(s4)
    8000495c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004960:	4501                	li	a0,0
    80004962:	a025                	j	8000498a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004964:	6088                	ld	a0,0(s1)
    80004966:	e501                	bnez	a0,8000496e <pipealloc+0xaa>
    80004968:	a039                	j	80004976 <pipealloc+0xb2>
    8000496a:	6088                	ld	a0,0(s1)
    8000496c:	c51d                	beqz	a0,8000499a <pipealloc+0xd6>
    fileclose(*f0);
    8000496e:	00000097          	auipc	ra,0x0
    80004972:	c2a080e7          	jalr	-982(ra) # 80004598 <fileclose>
  if(*f1)
    80004976:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000497a:	557d                	li	a0,-1
  if(*f1)
    8000497c:	c799                	beqz	a5,8000498a <pipealloc+0xc6>
    fileclose(*f1);
    8000497e:	853e                	mv	a0,a5
    80004980:	00000097          	auipc	ra,0x0
    80004984:	c18080e7          	jalr	-1000(ra) # 80004598 <fileclose>
  return -1;
    80004988:	557d                	li	a0,-1
}
    8000498a:	70a2                	ld	ra,40(sp)
    8000498c:	7402                	ld	s0,32(sp)
    8000498e:	64e2                	ld	s1,24(sp)
    80004990:	6942                	ld	s2,16(sp)
    80004992:	69a2                	ld	s3,8(sp)
    80004994:	6a02                	ld	s4,0(sp)
    80004996:	6145                	addi	sp,sp,48
    80004998:	8082                	ret
  return -1;
    8000499a:	557d                	li	a0,-1
    8000499c:	b7fd                	j	8000498a <pipealloc+0xc6>

000000008000499e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000499e:	1101                	addi	sp,sp,-32
    800049a0:	ec06                	sd	ra,24(sp)
    800049a2:	e822                	sd	s0,16(sp)
    800049a4:	e426                	sd	s1,8(sp)
    800049a6:	e04a                	sd	s2,0(sp)
    800049a8:	1000                	addi	s0,sp,32
    800049aa:	84aa                	mv	s1,a0
    800049ac:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	29a080e7          	jalr	666(ra) # 80000c48 <acquire>
  if(writable){
    800049b6:	02090d63          	beqz	s2,800049f0 <pipeclose+0x52>
    pi->writeopen = 0;
    800049ba:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800049be:	21848513          	addi	a0,s1,536
    800049c2:	ffffd097          	auipc	ra,0xffffd
    800049c6:	79c080e7          	jalr	1948(ra) # 8000215e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800049ca:	2204b783          	ld	a5,544(s1)
    800049ce:	eb95                	bnez	a5,80004a02 <pipeclose+0x64>
    release(&pi->lock);
    800049d0:	8526                	mv	a0,s1
    800049d2:	ffffc097          	auipc	ra,0xffffc
    800049d6:	32a080e7          	jalr	810(ra) # 80000cfc <release>
    kfree((char*)pi);
    800049da:	8526                	mv	a0,s1
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	07e080e7          	jalr	126(ra) # 80000a5a <kfree>
  } else
    release(&pi->lock);
}
    800049e4:	60e2                	ld	ra,24(sp)
    800049e6:	6442                	ld	s0,16(sp)
    800049e8:	64a2                	ld	s1,8(sp)
    800049ea:	6902                	ld	s2,0(sp)
    800049ec:	6105                	addi	sp,sp,32
    800049ee:	8082                	ret
    pi->readopen = 0;
    800049f0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800049f4:	21c48513          	addi	a0,s1,540
    800049f8:	ffffd097          	auipc	ra,0xffffd
    800049fc:	766080e7          	jalr	1894(ra) # 8000215e <wakeup>
    80004a00:	b7e9                	j	800049ca <pipeclose+0x2c>
    release(&pi->lock);
    80004a02:	8526                	mv	a0,s1
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	2f8080e7          	jalr	760(ra) # 80000cfc <release>
}
    80004a0c:	bfe1                	j	800049e4 <pipeclose+0x46>

0000000080004a0e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a0e:	711d                	addi	sp,sp,-96
    80004a10:	ec86                	sd	ra,88(sp)
    80004a12:	e8a2                	sd	s0,80(sp)
    80004a14:	e4a6                	sd	s1,72(sp)
    80004a16:	e0ca                	sd	s2,64(sp)
    80004a18:	fc4e                	sd	s3,56(sp)
    80004a1a:	f852                	sd	s4,48(sp)
    80004a1c:	f456                	sd	s5,40(sp)
    80004a1e:	f05a                	sd	s6,32(sp)
    80004a20:	ec5e                	sd	s7,24(sp)
    80004a22:	e862                	sd	s8,16(sp)
    80004a24:	1080                	addi	s0,sp,96
    80004a26:	84aa                	mv	s1,a0
    80004a28:	8aae                	mv	s5,a1
    80004a2a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a2c:	ffffd097          	auipc	ra,0xffffd
    80004a30:	ff8080e7          	jalr	-8(ra) # 80001a24 <myproc>
    80004a34:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004a36:	8526                	mv	a0,s1
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	210080e7          	jalr	528(ra) # 80000c48 <acquire>
  while(i < n){
    80004a40:	0b405663          	blez	s4,80004aec <pipewrite+0xde>
  int i = 0;
    80004a44:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004a46:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004a48:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004a4c:	21c48b93          	addi	s7,s1,540
    80004a50:	a089                	j	80004a92 <pipewrite+0x84>
      release(&pi->lock);
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	2a8080e7          	jalr	680(ra) # 80000cfc <release>
      return -1;
    80004a5c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004a5e:	854a                	mv	a0,s2
    80004a60:	60e6                	ld	ra,88(sp)
    80004a62:	6446                	ld	s0,80(sp)
    80004a64:	64a6                	ld	s1,72(sp)
    80004a66:	6906                	ld	s2,64(sp)
    80004a68:	79e2                	ld	s3,56(sp)
    80004a6a:	7a42                	ld	s4,48(sp)
    80004a6c:	7aa2                	ld	s5,40(sp)
    80004a6e:	7b02                	ld	s6,32(sp)
    80004a70:	6be2                	ld	s7,24(sp)
    80004a72:	6c42                	ld	s8,16(sp)
    80004a74:	6125                	addi	sp,sp,96
    80004a76:	8082                	ret
      wakeup(&pi->nread);
    80004a78:	8562                	mv	a0,s8
    80004a7a:	ffffd097          	auipc	ra,0xffffd
    80004a7e:	6e4080e7          	jalr	1764(ra) # 8000215e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004a82:	85a6                	mv	a1,s1
    80004a84:	855e                	mv	a0,s7
    80004a86:	ffffd097          	auipc	ra,0xffffd
    80004a8a:	674080e7          	jalr	1652(ra) # 800020fa <sleep>
  while(i < n){
    80004a8e:	07495063          	bge	s2,s4,80004aee <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004a92:	2204a783          	lw	a5,544(s1)
    80004a96:	dfd5                	beqz	a5,80004a52 <pipewrite+0x44>
    80004a98:	854e                	mv	a0,s3
    80004a9a:	ffffe097          	auipc	ra,0xffffe
    80004a9e:	908080e7          	jalr	-1784(ra) # 800023a2 <killed>
    80004aa2:	f945                	bnez	a0,80004a52 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004aa4:	2184a783          	lw	a5,536(s1)
    80004aa8:	21c4a703          	lw	a4,540(s1)
    80004aac:	2007879b          	addiw	a5,a5,512
    80004ab0:	fcf704e3          	beq	a4,a5,80004a78 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ab4:	4685                	li	a3,1
    80004ab6:	01590633          	add	a2,s2,s5
    80004aba:	faf40593          	addi	a1,s0,-81
    80004abe:	0509b503          	ld	a0,80(s3)
    80004ac2:	ffffd097          	auipc	ra,0xffffd
    80004ac6:	cae080e7          	jalr	-850(ra) # 80001770 <copyin>
    80004aca:	03650263          	beq	a0,s6,80004aee <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ace:	21c4a783          	lw	a5,540(s1)
    80004ad2:	0017871b          	addiw	a4,a5,1
    80004ad6:	20e4ae23          	sw	a4,540(s1)
    80004ada:	1ff7f793          	andi	a5,a5,511
    80004ade:	97a6                	add	a5,a5,s1
    80004ae0:	faf44703          	lbu	a4,-81(s0)
    80004ae4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004ae8:	2905                	addiw	s2,s2,1
    80004aea:	b755                	j	80004a8e <pipewrite+0x80>
  int i = 0;
    80004aec:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004aee:	21848513          	addi	a0,s1,536
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	66c080e7          	jalr	1644(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	200080e7          	jalr	512(ra) # 80000cfc <release>
  return i;
    80004b04:	bfa9                	j	80004a5e <pipewrite+0x50>

0000000080004b06 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b06:	715d                	addi	sp,sp,-80
    80004b08:	e486                	sd	ra,72(sp)
    80004b0a:	e0a2                	sd	s0,64(sp)
    80004b0c:	fc26                	sd	s1,56(sp)
    80004b0e:	f84a                	sd	s2,48(sp)
    80004b10:	f44e                	sd	s3,40(sp)
    80004b12:	f052                	sd	s4,32(sp)
    80004b14:	ec56                	sd	s5,24(sp)
    80004b16:	e85a                	sd	s6,16(sp)
    80004b18:	0880                	addi	s0,sp,80
    80004b1a:	84aa                	mv	s1,a0
    80004b1c:	892e                	mv	s2,a1
    80004b1e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	f04080e7          	jalr	-252(ra) # 80001a24 <myproc>
    80004b28:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	11c080e7          	jalr	284(ra) # 80000c48 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b34:	2184a703          	lw	a4,536(s1)
    80004b38:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b3c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b40:	02f71763          	bne	a4,a5,80004b6e <piperead+0x68>
    80004b44:	2244a783          	lw	a5,548(s1)
    80004b48:	c39d                	beqz	a5,80004b6e <piperead+0x68>
    if(killed(pr)){
    80004b4a:	8552                	mv	a0,s4
    80004b4c:	ffffe097          	auipc	ra,0xffffe
    80004b50:	856080e7          	jalr	-1962(ra) # 800023a2 <killed>
    80004b54:	e949                	bnez	a0,80004be6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004b56:	85a6                	mv	a1,s1
    80004b58:	854e                	mv	a0,s3
    80004b5a:	ffffd097          	auipc	ra,0xffffd
    80004b5e:	5a0080e7          	jalr	1440(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004b62:	2184a703          	lw	a4,536(s1)
    80004b66:	21c4a783          	lw	a5,540(s1)
    80004b6a:	fcf70de3          	beq	a4,a5,80004b44 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b6e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b70:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004b72:	05505463          	blez	s5,80004bba <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004b76:	2184a783          	lw	a5,536(s1)
    80004b7a:	21c4a703          	lw	a4,540(s1)
    80004b7e:	02f70e63          	beq	a4,a5,80004bba <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004b82:	0017871b          	addiw	a4,a5,1
    80004b86:	20e4ac23          	sw	a4,536(s1)
    80004b8a:	1ff7f793          	andi	a5,a5,511
    80004b8e:	97a6                	add	a5,a5,s1
    80004b90:	0187c783          	lbu	a5,24(a5)
    80004b94:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004b98:	4685                	li	a3,1
    80004b9a:	fbf40613          	addi	a2,s0,-65
    80004b9e:	85ca                	mv	a1,s2
    80004ba0:	050a3503          	ld	a0,80(s4)
    80004ba4:	ffffd097          	auipc	ra,0xffffd
    80004ba8:	b40080e7          	jalr	-1216(ra) # 800016e4 <copyout>
    80004bac:	01650763          	beq	a0,s6,80004bba <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bb0:	2985                	addiw	s3,s3,1
    80004bb2:	0905                	addi	s2,s2,1
    80004bb4:	fd3a91e3          	bne	s5,s3,80004b76 <piperead+0x70>
    80004bb8:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004bba:	21c48513          	addi	a0,s1,540
    80004bbe:	ffffd097          	auipc	ra,0xffffd
    80004bc2:	5a0080e7          	jalr	1440(ra) # 8000215e <wakeup>
  release(&pi->lock);
    80004bc6:	8526                	mv	a0,s1
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	134080e7          	jalr	308(ra) # 80000cfc <release>
  return i;
}
    80004bd0:	854e                	mv	a0,s3
    80004bd2:	60a6                	ld	ra,72(sp)
    80004bd4:	6406                	ld	s0,64(sp)
    80004bd6:	74e2                	ld	s1,56(sp)
    80004bd8:	7942                	ld	s2,48(sp)
    80004bda:	79a2                	ld	s3,40(sp)
    80004bdc:	7a02                	ld	s4,32(sp)
    80004bde:	6ae2                	ld	s5,24(sp)
    80004be0:	6b42                	ld	s6,16(sp)
    80004be2:	6161                	addi	sp,sp,80
    80004be4:	8082                	ret
      release(&pi->lock);
    80004be6:	8526                	mv	a0,s1
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	114080e7          	jalr	276(ra) # 80000cfc <release>
      return -1;
    80004bf0:	59fd                	li	s3,-1
    80004bf2:	bff9                	j	80004bd0 <piperead+0xca>

0000000080004bf4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004bf4:	1141                	addi	sp,sp,-16
    80004bf6:	e422                	sd	s0,8(sp)
    80004bf8:	0800                	addi	s0,sp,16
    80004bfa:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004bfc:	8905                	andi	a0,a0,1
    80004bfe:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c00:	8b89                	andi	a5,a5,2
    80004c02:	c399                	beqz	a5,80004c08 <flags2perm+0x14>
      perm |= PTE_W;
    80004c04:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c08:	6422                	ld	s0,8(sp)
    80004c0a:	0141                	addi	sp,sp,16
    80004c0c:	8082                	ret

0000000080004c0e <exec>:

int
exec(char *path, char **argv)
{
    80004c0e:	df010113          	addi	sp,sp,-528
    80004c12:	20113423          	sd	ra,520(sp)
    80004c16:	20813023          	sd	s0,512(sp)
    80004c1a:	ffa6                	sd	s1,504(sp)
    80004c1c:	fbca                	sd	s2,496(sp)
    80004c1e:	f7ce                	sd	s3,488(sp)
    80004c20:	f3d2                	sd	s4,480(sp)
    80004c22:	efd6                	sd	s5,472(sp)
    80004c24:	ebda                	sd	s6,464(sp)
    80004c26:	e7de                	sd	s7,456(sp)
    80004c28:	e3e2                	sd	s8,448(sp)
    80004c2a:	ff66                	sd	s9,440(sp)
    80004c2c:	fb6a                	sd	s10,432(sp)
    80004c2e:	f76e                	sd	s11,424(sp)
    80004c30:	0c00                	addi	s0,sp,528
    80004c32:	892a                	mv	s2,a0
    80004c34:	dea43c23          	sd	a0,-520(s0)
    80004c38:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c3c:	ffffd097          	auipc	ra,0xffffd
    80004c40:	de8080e7          	jalr	-536(ra) # 80001a24 <myproc>
    80004c44:	84aa                	mv	s1,a0

  begin_op();
    80004c46:	fffff097          	auipc	ra,0xfffff
    80004c4a:	48e080e7          	jalr	1166(ra) # 800040d4 <begin_op>

  if((ip = namei(path)) == 0){
    80004c4e:	854a                	mv	a0,s2
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	284080e7          	jalr	644(ra) # 80003ed4 <namei>
    80004c58:	c92d                	beqz	a0,80004cca <exec+0xbc>
    80004c5a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	ad2080e7          	jalr	-1326(ra) # 8000372e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004c64:	04000713          	li	a4,64
    80004c68:	4681                	li	a3,0
    80004c6a:	e5040613          	addi	a2,s0,-432
    80004c6e:	4581                	li	a1,0
    80004c70:	8552                	mv	a0,s4
    80004c72:	fffff097          	auipc	ra,0xfffff
    80004c76:	d70080e7          	jalr	-656(ra) # 800039e2 <readi>
    80004c7a:	04000793          	li	a5,64
    80004c7e:	00f51a63          	bne	a0,a5,80004c92 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004c82:	e5042703          	lw	a4,-432(s0)
    80004c86:	464c47b7          	lui	a5,0x464c4
    80004c8a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004c8e:	04f70463          	beq	a4,a5,80004cd6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004c92:	8552                	mv	a0,s4
    80004c94:	fffff097          	auipc	ra,0xfffff
    80004c98:	cfc080e7          	jalr	-772(ra) # 80003990 <iunlockput>
    end_op();
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	4b2080e7          	jalr	1202(ra) # 8000414e <end_op>
  }
  return -1;
    80004ca4:	557d                	li	a0,-1
}
    80004ca6:	20813083          	ld	ra,520(sp)
    80004caa:	20013403          	ld	s0,512(sp)
    80004cae:	74fe                	ld	s1,504(sp)
    80004cb0:	795e                	ld	s2,496(sp)
    80004cb2:	79be                	ld	s3,488(sp)
    80004cb4:	7a1e                	ld	s4,480(sp)
    80004cb6:	6afe                	ld	s5,472(sp)
    80004cb8:	6b5e                	ld	s6,464(sp)
    80004cba:	6bbe                	ld	s7,456(sp)
    80004cbc:	6c1e                	ld	s8,448(sp)
    80004cbe:	7cfa                	ld	s9,440(sp)
    80004cc0:	7d5a                	ld	s10,432(sp)
    80004cc2:	7dba                	ld	s11,424(sp)
    80004cc4:	21010113          	addi	sp,sp,528
    80004cc8:	8082                	ret
    end_op();
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	484080e7          	jalr	1156(ra) # 8000414e <end_op>
    return -1;
    80004cd2:	557d                	li	a0,-1
    80004cd4:	bfc9                	j	80004ca6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	e10080e7          	jalr	-496(ra) # 80001ae8 <proc_pagetable>
    80004ce0:	8b2a                	mv	s6,a0
    80004ce2:	d945                	beqz	a0,80004c92 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ce4:	e7042d03          	lw	s10,-400(s0)
    80004ce8:	e8845783          	lhu	a5,-376(s0)
    80004cec:	10078463          	beqz	a5,80004df4 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004cf0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004cf2:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004cf4:	6c85                	lui	s9,0x1
    80004cf6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004cfa:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004cfe:	6a85                	lui	s5,0x1
    80004d00:	a0b5                	j	80004d6c <exec+0x15e>
      panic("loadseg: address should exist");
    80004d02:	00004517          	auipc	a0,0x4
    80004d06:	9d650513          	addi	a0,a0,-1578 # 800086d8 <syscalls+0x280>
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	836080e7          	jalr	-1994(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
    80004d12:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d14:	8726                	mv	a4,s1
    80004d16:	012c06bb          	addw	a3,s8,s2
    80004d1a:	4581                	li	a1,0
    80004d1c:	8552                	mv	a0,s4
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	cc4080e7          	jalr	-828(ra) # 800039e2 <readi>
    80004d26:	2501                	sext.w	a0,a0
    80004d28:	2aa49963          	bne	s1,a0,80004fda <exec+0x3cc>
  for(i = 0; i < sz; i += PGSIZE){
    80004d2c:	012a893b          	addw	s2,s5,s2
    80004d30:	03397563          	bgeu	s2,s3,80004d5a <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    80004d34:	02091593          	slli	a1,s2,0x20
    80004d38:	9181                	srli	a1,a1,0x20
    80004d3a:	95de                	add	a1,a1,s7
    80004d3c:	855a                	mv	a0,s6
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	396080e7          	jalr	918(ra) # 800010d4 <walkaddr>
    80004d46:	862a                	mv	a2,a0
    if(pa == 0)
    80004d48:	dd4d                	beqz	a0,80004d02 <exec+0xf4>
    if(sz - i < PGSIZE)
    80004d4a:	412984bb          	subw	s1,s3,s2
    80004d4e:	0004879b          	sext.w	a5,s1
    80004d52:	fcfcf0e3          	bgeu	s9,a5,80004d12 <exec+0x104>
    80004d56:	84d6                	mv	s1,s5
    80004d58:	bf6d                	j	80004d12 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004d5a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d5e:	2d85                	addiw	s11,s11,1
    80004d60:	038d0d1b          	addiw	s10,s10,56
    80004d64:	e8845783          	lhu	a5,-376(s0)
    80004d68:	08fdd763          	bge	s11,a5,80004df6 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004d6c:	2d01                	sext.w	s10,s10
    80004d6e:	03800713          	li	a4,56
    80004d72:	86ea                	mv	a3,s10
    80004d74:	e1840613          	addi	a2,s0,-488
    80004d78:	4581                	li	a1,0
    80004d7a:	8552                	mv	a0,s4
    80004d7c:	fffff097          	auipc	ra,0xfffff
    80004d80:	c66080e7          	jalr	-922(ra) # 800039e2 <readi>
    80004d84:	03800793          	li	a5,56
    80004d88:	24f51763          	bne	a0,a5,80004fd6 <exec+0x3c8>
    if(ph.type != ELF_PROG_LOAD)
    80004d8c:	e1842783          	lw	a5,-488(s0)
    80004d90:	4705                	li	a4,1
    80004d92:	fce796e3          	bne	a5,a4,80004d5e <exec+0x150>
    if(ph.memsz < ph.filesz)
    80004d96:	e4043483          	ld	s1,-448(s0)
    80004d9a:	e3843783          	ld	a5,-456(s0)
    80004d9e:	24f4e963          	bltu	s1,a5,80004ff0 <exec+0x3e2>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004da2:	e2843783          	ld	a5,-472(s0)
    80004da6:	94be                	add	s1,s1,a5
    80004da8:	24f4e763          	bltu	s1,a5,80004ff6 <exec+0x3e8>
    if(ph.vaddr % PGSIZE != 0)
    80004dac:	df043703          	ld	a4,-528(s0)
    80004db0:	8ff9                	and	a5,a5,a4
    80004db2:	24079563          	bnez	a5,80004ffc <exec+0x3ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004db6:	e1c42503          	lw	a0,-484(s0)
    80004dba:	00000097          	auipc	ra,0x0
    80004dbe:	e3a080e7          	jalr	-454(ra) # 80004bf4 <flags2perm>
    80004dc2:	86aa                	mv	a3,a0
    80004dc4:	8626                	mv	a2,s1
    80004dc6:	85ca                	mv	a1,s2
    80004dc8:	855a                	mv	a0,s6
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	6be080e7          	jalr	1726(ra) # 80001488 <uvmalloc>
    80004dd2:	e0a43423          	sd	a0,-504(s0)
    80004dd6:	22050663          	beqz	a0,80005002 <exec+0x3f4>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004dda:	e2843b83          	ld	s7,-472(s0)
    80004dde:	e2042c03          	lw	s8,-480(s0)
    80004de2:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004de6:	00098463          	beqz	s3,80004dee <exec+0x1e0>
    80004dea:	4901                	li	s2,0
    80004dec:	b7a1                	j	80004d34 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004dee:	e0843903          	ld	s2,-504(s0)
    80004df2:	b7b5                	j	80004d5e <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004df4:	4901                	li	s2,0
  iunlockput(ip);
    80004df6:	8552                	mv	a0,s4
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	b98080e7          	jalr	-1128(ra) # 80003990 <iunlockput>
  end_op();
    80004e00:	fffff097          	auipc	ra,0xfffff
    80004e04:	34e080e7          	jalr	846(ra) # 8000414e <end_op>
  p = myproc();
    80004e08:	ffffd097          	auipc	ra,0xffffd
    80004e0c:	c1c080e7          	jalr	-996(ra) # 80001a24 <myproc>
    80004e10:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e12:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004e16:	6985                	lui	s3,0x1
    80004e18:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004e1a:	99ca                	add	s3,s3,s2
    80004e1c:	77fd                	lui	a5,0xfffff
    80004e1e:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e22:	4691                	li	a3,4
    80004e24:	6609                	lui	a2,0x2
    80004e26:	964e                	add	a2,a2,s3
    80004e28:	85ce                	mv	a1,s3
    80004e2a:	855a                	mv	a0,s6
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	65c080e7          	jalr	1628(ra) # 80001488 <uvmalloc>
    80004e34:	892a                	mv	s2,a0
    80004e36:	e0a43423          	sd	a0,-504(s0)
    80004e3a:	e509                	bnez	a0,80004e44 <exec+0x236>
  if(pagetable)
    80004e3c:	e1343423          	sd	s3,-504(s0)
    80004e40:	4a01                	li	s4,0
    80004e42:	aa61                	j	80004fda <exec+0x3cc>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e44:	75f9                	lui	a1,0xffffe
    80004e46:	95aa                	add	a1,a1,a0
    80004e48:	855a                	mv	a0,s6
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	868080e7          	jalr	-1944(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e52:	7bfd                	lui	s7,0xfffff
    80004e54:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004e56:	e0043783          	ld	a5,-512(s0)
    80004e5a:	6388                	ld	a0,0(a5)
    80004e5c:	c52d                	beqz	a0,80004ec6 <exec+0x2b8>
    80004e5e:	e9040993          	addi	s3,s0,-368
    80004e62:	f9040c13          	addi	s8,s0,-112
    80004e66:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	056080e7          	jalr	86(ra) # 80000ebe <strlen>
    80004e70:	0015079b          	addiw	a5,a0,1
    80004e74:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e78:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e7c:	19796663          	bltu	s2,s7,80005008 <exec+0x3fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e80:	e0043d03          	ld	s10,-512(s0)
    80004e84:	000d3a03          	ld	s4,0(s10)
    80004e88:	8552                	mv	a0,s4
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	034080e7          	jalr	52(ra) # 80000ebe <strlen>
    80004e92:	0015069b          	addiw	a3,a0,1
    80004e96:	8652                	mv	a2,s4
    80004e98:	85ca                	mv	a1,s2
    80004e9a:	855a                	mv	a0,s6
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	848080e7          	jalr	-1976(ra) # 800016e4 <copyout>
    80004ea4:	16054463          	bltz	a0,8000500c <exec+0x3fe>
    ustack[argc] = sp;
    80004ea8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eac:	0485                	addi	s1,s1,1
    80004eae:	008d0793          	addi	a5,s10,8
    80004eb2:	e0f43023          	sd	a5,-512(s0)
    80004eb6:	008d3503          	ld	a0,8(s10)
    80004eba:	c909                	beqz	a0,80004ecc <exec+0x2be>
    if(argc >= MAXARG)
    80004ebc:	09a1                	addi	s3,s3,8
    80004ebe:	fb8995e3          	bne	s3,s8,80004e68 <exec+0x25a>
  ip = 0;
    80004ec2:	4a01                	li	s4,0
    80004ec4:	aa19                	j	80004fda <exec+0x3cc>
  sp = sz;
    80004ec6:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004eca:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ecc:	00349793          	slli	a5,s1,0x3
    80004ed0:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdc650>
    80004ed4:	97a2                	add	a5,a5,s0
    80004ed6:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004eda:	00148693          	addi	a3,s1,1
    80004ede:	068e                	slli	a3,a3,0x3
    80004ee0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee4:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004ee8:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004eec:	f57968e3          	bltu	s2,s7,80004e3c <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef0:	e9040613          	addi	a2,s0,-368
    80004ef4:	85ca                	mv	a1,s2
    80004ef6:	855a                	mv	a0,s6
    80004ef8:	ffffc097          	auipc	ra,0xffffc
    80004efc:	7ec080e7          	jalr	2028(ra) # 800016e4 <copyout>
    80004f00:	10054863          	bltz	a0,80005010 <exec+0x402>
  p->trapframe->a1 = sp;
    80004f04:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004f08:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f0c:	df843783          	ld	a5,-520(s0)
    80004f10:	0007c703          	lbu	a4,0(a5)
    80004f14:	cf11                	beqz	a4,80004f30 <exec+0x322>
    80004f16:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f18:	02f00693          	li	a3,47
    80004f1c:	a039                	j	80004f2a <exec+0x31c>
      last = s+1;
    80004f1e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f22:	0785                	addi	a5,a5,1
    80004f24:	fff7c703          	lbu	a4,-1(a5)
    80004f28:	c701                	beqz	a4,80004f30 <exec+0x322>
    if(*s == '/')
    80004f2a:	fed71ce3          	bne	a4,a3,80004f22 <exec+0x314>
    80004f2e:	bfc5                	j	80004f1e <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f30:	158a8993          	addi	s3,s5,344
    80004f34:	4641                	li	a2,16
    80004f36:	df843583          	ld	a1,-520(s0)
    80004f3a:	854e                	mv	a0,s3
    80004f3c:	ffffc097          	auipc	ra,0xffffc
    80004f40:	f50080e7          	jalr	-176(ra) # 80000e8c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f44:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f48:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004f4c:	e0843783          	ld	a5,-504(s0)
    80004f50:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f54:	058ab783          	ld	a5,88(s5)
    80004f58:	e6843703          	ld	a4,-408(s0)
    80004f5c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f5e:	058ab783          	ld	a5,88(s5)
    80004f62:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f66:	85e6                	mv	a1,s9
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	c1c080e7          	jalr	-996(ra) # 80001b84 <proc_freepagetable>
  if (strncmp(p->name, "vm-", 3) == 0) {
    80004f70:	460d                	li	a2,3
    80004f72:	00003597          	auipc	a1,0x3
    80004f76:	28e58593          	addi	a1,a1,654 # 80008200 <digits+0x1c0>
    80004f7a:	854e                	mv	a0,s3
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	e98080e7          	jalr	-360(ra) # 80000e14 <strncmp>
    80004f84:	c501                	beqz	a0,80004f8c <exec+0x37e>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f86:	0004851b          	sext.w	a0,s1
    80004f8a:	bb31                	j	80004ca6 <exec+0x98>
    if((sz1 = uvmalloc(pagetable, memaddr, memaddr + 1024*PGSIZE, PTE_W)) == 0) {
    80004f8c:	4691                	li	a3,4
    80004f8e:	20100613          	li	a2,513
    80004f92:	065a                	slli	a2,a2,0x16
    80004f94:	4585                	li	a1,1
    80004f96:	05fe                	slli	a1,a1,0x1f
    80004f98:	855a                	mv	a0,s6
    80004f9a:	ffffc097          	auipc	ra,0xffffc
    80004f9e:	4ee080e7          	jalr	1262(ra) # 80001488 <uvmalloc>
    80004fa2:	cd19                	beqz	a0,80004fc0 <exec+0x3b2>
    printf("Created a VM process and allocated memory region (%p - %p).\n", memaddr, memaddr + 1024*PGSIZE);
    80004fa4:	20100613          	li	a2,513
    80004fa8:	065a                	slli	a2,a2,0x16
    80004faa:	4585                	li	a1,1
    80004fac:	05fe                	slli	a1,a1,0x1f
    80004fae:	00003517          	auipc	a0,0x3
    80004fb2:	78250513          	addi	a0,a0,1922 # 80008730 <syscalls+0x2d8>
    80004fb6:	ffffb097          	auipc	ra,0xffffb
    80004fba:	5d4080e7          	jalr	1492(ra) # 8000058a <printf>
    80004fbe:	b7e1                	j	80004f86 <exec+0x378>
      printf("Error: could not allocate memory at 0x80000000 for VM.\n");
    80004fc0:	00003517          	auipc	a0,0x3
    80004fc4:	73850513          	addi	a0,a0,1848 # 800086f8 <syscalls+0x2a0>
    80004fc8:	ffffb097          	auipc	ra,0xffffb
    80004fcc:	5c2080e7          	jalr	1474(ra) # 8000058a <printf>
  sz = sz1;
    80004fd0:	e0843983          	ld	s3,-504(s0)
      goto bad;
    80004fd4:	b5a5                	j	80004e3c <exec+0x22e>
    80004fd6:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fda:	e0843583          	ld	a1,-504(s0)
    80004fde:	855a                	mv	a0,s6
    80004fe0:	ffffd097          	auipc	ra,0xffffd
    80004fe4:	ba4080e7          	jalr	-1116(ra) # 80001b84 <proc_freepagetable>
  return -1;
    80004fe8:	557d                	li	a0,-1
  if(ip){
    80004fea:	ca0a0ee3          	beqz	s4,80004ca6 <exec+0x98>
    80004fee:	b155                	j	80004c92 <exec+0x84>
    80004ff0:	e1243423          	sd	s2,-504(s0)
    80004ff4:	b7dd                	j	80004fda <exec+0x3cc>
    80004ff6:	e1243423          	sd	s2,-504(s0)
    80004ffa:	b7c5                	j	80004fda <exec+0x3cc>
    80004ffc:	e1243423          	sd	s2,-504(s0)
    80005000:	bfe9                	j	80004fda <exec+0x3cc>
    80005002:	e1243423          	sd	s2,-504(s0)
    80005006:	bfd1                	j	80004fda <exec+0x3cc>
  ip = 0;
    80005008:	4a01                	li	s4,0
    8000500a:	bfc1                	j	80004fda <exec+0x3cc>
    8000500c:	4a01                	li	s4,0
  if(pagetable)
    8000500e:	b7f1                	j	80004fda <exec+0x3cc>
  sz = sz1;
    80005010:	e0843983          	ld	s3,-504(s0)
    80005014:	b525                	j	80004e3c <exec+0x22e>

0000000080005016 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005016:	7179                	addi	sp,sp,-48
    80005018:	f406                	sd	ra,40(sp)
    8000501a:	f022                	sd	s0,32(sp)
    8000501c:	ec26                	sd	s1,24(sp)
    8000501e:	e84a                	sd	s2,16(sp)
    80005020:	1800                	addi	s0,sp,48
    80005022:	892e                	mv	s2,a1
    80005024:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005026:	fdc40593          	addi	a1,s0,-36
    8000502a:	ffffe097          	auipc	ra,0xffffe
    8000502e:	ba2080e7          	jalr	-1118(ra) # 80002bcc <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005032:	fdc42703          	lw	a4,-36(s0)
    80005036:	47bd                	li	a5,15
    80005038:	02e7eb63          	bltu	a5,a4,8000506e <argfd+0x58>
    8000503c:	ffffd097          	auipc	ra,0xffffd
    80005040:	9e8080e7          	jalr	-1560(ra) # 80001a24 <myproc>
    80005044:	fdc42703          	lw	a4,-36(s0)
    80005048:	01a70793          	addi	a5,a4,26
    8000504c:	078e                	slli	a5,a5,0x3
    8000504e:	953e                	add	a0,a0,a5
    80005050:	611c                	ld	a5,0(a0)
    80005052:	c385                	beqz	a5,80005072 <argfd+0x5c>
    return -1;
  if(pfd)
    80005054:	00090463          	beqz	s2,8000505c <argfd+0x46>
    *pfd = fd;
    80005058:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000505c:	4501                	li	a0,0
  if(pf)
    8000505e:	c091                	beqz	s1,80005062 <argfd+0x4c>
    *pf = f;
    80005060:	e09c                	sd	a5,0(s1)
}
    80005062:	70a2                	ld	ra,40(sp)
    80005064:	7402                	ld	s0,32(sp)
    80005066:	64e2                	ld	s1,24(sp)
    80005068:	6942                	ld	s2,16(sp)
    8000506a:	6145                	addi	sp,sp,48
    8000506c:	8082                	ret
    return -1;
    8000506e:	557d                	li	a0,-1
    80005070:	bfcd                	j	80005062 <argfd+0x4c>
    80005072:	557d                	li	a0,-1
    80005074:	b7fd                	j	80005062 <argfd+0x4c>

0000000080005076 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005076:	1101                	addi	sp,sp,-32
    80005078:	ec06                	sd	ra,24(sp)
    8000507a:	e822                	sd	s0,16(sp)
    8000507c:	e426                	sd	s1,8(sp)
    8000507e:	1000                	addi	s0,sp,32
    80005080:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	9a2080e7          	jalr	-1630(ra) # 80001a24 <myproc>
    8000508a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000508c:	0d050793          	addi	a5,a0,208
    80005090:	4501                	li	a0,0
    80005092:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005094:	6398                	ld	a4,0(a5)
    80005096:	cb19                	beqz	a4,800050ac <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005098:	2505                	addiw	a0,a0,1
    8000509a:	07a1                	addi	a5,a5,8
    8000509c:	fed51ce3          	bne	a0,a3,80005094 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050a0:	557d                	li	a0,-1
}
    800050a2:	60e2                	ld	ra,24(sp)
    800050a4:	6442                	ld	s0,16(sp)
    800050a6:	64a2                	ld	s1,8(sp)
    800050a8:	6105                	addi	sp,sp,32
    800050aa:	8082                	ret
      p->ofile[fd] = f;
    800050ac:	01a50793          	addi	a5,a0,26
    800050b0:	078e                	slli	a5,a5,0x3
    800050b2:	963e                	add	a2,a2,a5
    800050b4:	e204                	sd	s1,0(a2)
      return fd;
    800050b6:	b7f5                	j	800050a2 <fdalloc+0x2c>

00000000800050b8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050b8:	715d                	addi	sp,sp,-80
    800050ba:	e486                	sd	ra,72(sp)
    800050bc:	e0a2                	sd	s0,64(sp)
    800050be:	fc26                	sd	s1,56(sp)
    800050c0:	f84a                	sd	s2,48(sp)
    800050c2:	f44e                	sd	s3,40(sp)
    800050c4:	f052                	sd	s4,32(sp)
    800050c6:	ec56                	sd	s5,24(sp)
    800050c8:	e85a                	sd	s6,16(sp)
    800050ca:	0880                	addi	s0,sp,80
    800050cc:	8b2e                	mv	s6,a1
    800050ce:	89b2                	mv	s3,a2
    800050d0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050d2:	fb040593          	addi	a1,s0,-80
    800050d6:	fffff097          	auipc	ra,0xfffff
    800050da:	e1c080e7          	jalr	-484(ra) # 80003ef2 <nameiparent>
    800050de:	84aa                	mv	s1,a0
    800050e0:	14050b63          	beqz	a0,80005236 <create+0x17e>
    return 0;

  ilock(dp);
    800050e4:	ffffe097          	auipc	ra,0xffffe
    800050e8:	64a080e7          	jalr	1610(ra) # 8000372e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050ec:	4601                	li	a2,0
    800050ee:	fb040593          	addi	a1,s0,-80
    800050f2:	8526                	mv	a0,s1
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	b1e080e7          	jalr	-1250(ra) # 80003c12 <dirlookup>
    800050fc:	8aaa                	mv	s5,a0
    800050fe:	c921                	beqz	a0,8000514e <create+0x96>
    iunlockput(dp);
    80005100:	8526                	mv	a0,s1
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	88e080e7          	jalr	-1906(ra) # 80003990 <iunlockput>
    ilock(ip);
    8000510a:	8556                	mv	a0,s5
    8000510c:	ffffe097          	auipc	ra,0xffffe
    80005110:	622080e7          	jalr	1570(ra) # 8000372e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005114:	4789                	li	a5,2
    80005116:	02fb1563          	bne	s6,a5,80005140 <create+0x88>
    8000511a:	044ad783          	lhu	a5,68(s5)
    8000511e:	37f9                	addiw	a5,a5,-2
    80005120:	17c2                	slli	a5,a5,0x30
    80005122:	93c1                	srli	a5,a5,0x30
    80005124:	4705                	li	a4,1
    80005126:	00f76d63          	bltu	a4,a5,80005140 <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000512a:	8556                	mv	a0,s5
    8000512c:	60a6                	ld	ra,72(sp)
    8000512e:	6406                	ld	s0,64(sp)
    80005130:	74e2                	ld	s1,56(sp)
    80005132:	7942                	ld	s2,48(sp)
    80005134:	79a2                	ld	s3,40(sp)
    80005136:	7a02                	ld	s4,32(sp)
    80005138:	6ae2                	ld	s5,24(sp)
    8000513a:	6b42                	ld	s6,16(sp)
    8000513c:	6161                	addi	sp,sp,80
    8000513e:	8082                	ret
    iunlockput(ip);
    80005140:	8556                	mv	a0,s5
    80005142:	fffff097          	auipc	ra,0xfffff
    80005146:	84e080e7          	jalr	-1970(ra) # 80003990 <iunlockput>
    return 0;
    8000514a:	4a81                	li	s5,0
    8000514c:	bff9                	j	8000512a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000514e:	85da                	mv	a1,s6
    80005150:	4088                	lw	a0,0(s1)
    80005152:	ffffe097          	auipc	ra,0xffffe
    80005156:	444080e7          	jalr	1092(ra) # 80003596 <ialloc>
    8000515a:	8a2a                	mv	s4,a0
    8000515c:	c529                	beqz	a0,800051a6 <create+0xee>
  ilock(ip);
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	5d0080e7          	jalr	1488(ra) # 8000372e <ilock>
  ip->major = major;
    80005166:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000516a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000516e:	4905                	li	s2,1
    80005170:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005174:	8552                	mv	a0,s4
    80005176:	ffffe097          	auipc	ra,0xffffe
    8000517a:	4ec080e7          	jalr	1260(ra) # 80003662 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000517e:	032b0b63          	beq	s6,s2,800051b4 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005182:	004a2603          	lw	a2,4(s4)
    80005186:	fb040593          	addi	a1,s0,-80
    8000518a:	8526                	mv	a0,s1
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	c96080e7          	jalr	-874(ra) # 80003e22 <dirlink>
    80005194:	06054f63          	bltz	a0,80005212 <create+0x15a>
  iunlockput(dp);
    80005198:	8526                	mv	a0,s1
    8000519a:	ffffe097          	auipc	ra,0xffffe
    8000519e:	7f6080e7          	jalr	2038(ra) # 80003990 <iunlockput>
  return ip;
    800051a2:	8ad2                	mv	s5,s4
    800051a4:	b759                	j	8000512a <create+0x72>
    iunlockput(dp);
    800051a6:	8526                	mv	a0,s1
    800051a8:	ffffe097          	auipc	ra,0xffffe
    800051ac:	7e8080e7          	jalr	2024(ra) # 80003990 <iunlockput>
    return 0;
    800051b0:	8ad2                	mv	s5,s4
    800051b2:	bfa5                	j	8000512a <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051b4:	004a2603          	lw	a2,4(s4)
    800051b8:	00003597          	auipc	a1,0x3
    800051bc:	5b858593          	addi	a1,a1,1464 # 80008770 <syscalls+0x318>
    800051c0:	8552                	mv	a0,s4
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	c60080e7          	jalr	-928(ra) # 80003e22 <dirlink>
    800051ca:	04054463          	bltz	a0,80005212 <create+0x15a>
    800051ce:	40d0                	lw	a2,4(s1)
    800051d0:	00003597          	auipc	a1,0x3
    800051d4:	5a858593          	addi	a1,a1,1448 # 80008778 <syscalls+0x320>
    800051d8:	8552                	mv	a0,s4
    800051da:	fffff097          	auipc	ra,0xfffff
    800051de:	c48080e7          	jalr	-952(ra) # 80003e22 <dirlink>
    800051e2:	02054863          	bltz	a0,80005212 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800051e6:	004a2603          	lw	a2,4(s4)
    800051ea:	fb040593          	addi	a1,s0,-80
    800051ee:	8526                	mv	a0,s1
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	c32080e7          	jalr	-974(ra) # 80003e22 <dirlink>
    800051f8:	00054d63          	bltz	a0,80005212 <create+0x15a>
    dp->nlink++;  // for ".."
    800051fc:	04a4d783          	lhu	a5,74(s1)
    80005200:	2785                	addiw	a5,a5,1
    80005202:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005206:	8526                	mv	a0,s1
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	45a080e7          	jalr	1114(ra) # 80003662 <iupdate>
    80005210:	b761                	j	80005198 <create+0xe0>
  ip->nlink = 0;
    80005212:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005216:	8552                	mv	a0,s4
    80005218:	ffffe097          	auipc	ra,0xffffe
    8000521c:	44a080e7          	jalr	1098(ra) # 80003662 <iupdate>
  iunlockput(ip);
    80005220:	8552                	mv	a0,s4
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	76e080e7          	jalr	1902(ra) # 80003990 <iunlockput>
  iunlockput(dp);
    8000522a:	8526                	mv	a0,s1
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	764080e7          	jalr	1892(ra) # 80003990 <iunlockput>
  return 0;
    80005234:	bddd                	j	8000512a <create+0x72>
    return 0;
    80005236:	8aaa                	mv	s5,a0
    80005238:	bdcd                	j	8000512a <create+0x72>

000000008000523a <sys_dup>:
{
    8000523a:	7179                	addi	sp,sp,-48
    8000523c:	f406                	sd	ra,40(sp)
    8000523e:	f022                	sd	s0,32(sp)
    80005240:	ec26                	sd	s1,24(sp)
    80005242:	e84a                	sd	s2,16(sp)
    80005244:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005246:	fd840613          	addi	a2,s0,-40
    8000524a:	4581                	li	a1,0
    8000524c:	4501                	li	a0,0
    8000524e:	00000097          	auipc	ra,0x0
    80005252:	dc8080e7          	jalr	-568(ra) # 80005016 <argfd>
    return -1;
    80005256:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005258:	02054363          	bltz	a0,8000527e <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000525c:	fd843903          	ld	s2,-40(s0)
    80005260:	854a                	mv	a0,s2
    80005262:	00000097          	auipc	ra,0x0
    80005266:	e14080e7          	jalr	-492(ra) # 80005076 <fdalloc>
    8000526a:	84aa                	mv	s1,a0
    return -1;
    8000526c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000526e:	00054863          	bltz	a0,8000527e <sys_dup+0x44>
  filedup(f);
    80005272:	854a                	mv	a0,s2
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	2d2080e7          	jalr	722(ra) # 80004546 <filedup>
  return fd;
    8000527c:	87a6                	mv	a5,s1
}
    8000527e:	853e                	mv	a0,a5
    80005280:	70a2                	ld	ra,40(sp)
    80005282:	7402                	ld	s0,32(sp)
    80005284:	64e2                	ld	s1,24(sp)
    80005286:	6942                	ld	s2,16(sp)
    80005288:	6145                	addi	sp,sp,48
    8000528a:	8082                	ret

000000008000528c <sys_read>:
{
    8000528c:	7179                	addi	sp,sp,-48
    8000528e:	f406                	sd	ra,40(sp)
    80005290:	f022                	sd	s0,32(sp)
    80005292:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005294:	fd840593          	addi	a1,s0,-40
    80005298:	4505                	li	a0,1
    8000529a:	ffffe097          	auipc	ra,0xffffe
    8000529e:	952080e7          	jalr	-1710(ra) # 80002bec <argaddr>
  argint(2, &n);
    800052a2:	fe440593          	addi	a1,s0,-28
    800052a6:	4509                	li	a0,2
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	924080e7          	jalr	-1756(ra) # 80002bcc <argint>
  if(argfd(0, 0, &f) < 0)
    800052b0:	fe840613          	addi	a2,s0,-24
    800052b4:	4581                	li	a1,0
    800052b6:	4501                	li	a0,0
    800052b8:	00000097          	auipc	ra,0x0
    800052bc:	d5e080e7          	jalr	-674(ra) # 80005016 <argfd>
    800052c0:	87aa                	mv	a5,a0
    return -1;
    800052c2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800052c4:	0007cc63          	bltz	a5,800052dc <sys_read+0x50>
  return fileread(f, p, n);
    800052c8:	fe442603          	lw	a2,-28(s0)
    800052cc:	fd843583          	ld	a1,-40(s0)
    800052d0:	fe843503          	ld	a0,-24(s0)
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	3fe080e7          	jalr	1022(ra) # 800046d2 <fileread>
}
    800052dc:	70a2                	ld	ra,40(sp)
    800052de:	7402                	ld	s0,32(sp)
    800052e0:	6145                	addi	sp,sp,48
    800052e2:	8082                	ret

00000000800052e4 <sys_write>:
{
    800052e4:	7179                	addi	sp,sp,-48
    800052e6:	f406                	sd	ra,40(sp)
    800052e8:	f022                	sd	s0,32(sp)
    800052ea:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052ec:	fd840593          	addi	a1,s0,-40
    800052f0:	4505                	li	a0,1
    800052f2:	ffffe097          	auipc	ra,0xffffe
    800052f6:	8fa080e7          	jalr	-1798(ra) # 80002bec <argaddr>
  argint(2, &n);
    800052fa:	fe440593          	addi	a1,s0,-28
    800052fe:	4509                	li	a0,2
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	8cc080e7          	jalr	-1844(ra) # 80002bcc <argint>
  if(argfd(0, 0, &f) < 0)
    80005308:	fe840613          	addi	a2,s0,-24
    8000530c:	4581                	li	a1,0
    8000530e:	4501                	li	a0,0
    80005310:	00000097          	auipc	ra,0x0
    80005314:	d06080e7          	jalr	-762(ra) # 80005016 <argfd>
    80005318:	87aa                	mv	a5,a0
    return -1;
    8000531a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000531c:	0007cc63          	bltz	a5,80005334 <sys_write+0x50>
  return filewrite(f, p, n);
    80005320:	fe442603          	lw	a2,-28(s0)
    80005324:	fd843583          	ld	a1,-40(s0)
    80005328:	fe843503          	ld	a0,-24(s0)
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	468080e7          	jalr	1128(ra) # 80004794 <filewrite>
}
    80005334:	70a2                	ld	ra,40(sp)
    80005336:	7402                	ld	s0,32(sp)
    80005338:	6145                	addi	sp,sp,48
    8000533a:	8082                	ret

000000008000533c <sys_close>:
{
    8000533c:	1101                	addi	sp,sp,-32
    8000533e:	ec06                	sd	ra,24(sp)
    80005340:	e822                	sd	s0,16(sp)
    80005342:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005344:	fe040613          	addi	a2,s0,-32
    80005348:	fec40593          	addi	a1,s0,-20
    8000534c:	4501                	li	a0,0
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	cc8080e7          	jalr	-824(ra) # 80005016 <argfd>
    return -1;
    80005356:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005358:	02054463          	bltz	a0,80005380 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000535c:	ffffc097          	auipc	ra,0xffffc
    80005360:	6c8080e7          	jalr	1736(ra) # 80001a24 <myproc>
    80005364:	fec42783          	lw	a5,-20(s0)
    80005368:	07e9                	addi	a5,a5,26
    8000536a:	078e                	slli	a5,a5,0x3
    8000536c:	953e                	add	a0,a0,a5
    8000536e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005372:	fe043503          	ld	a0,-32(s0)
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	222080e7          	jalr	546(ra) # 80004598 <fileclose>
  return 0;
    8000537e:	4781                	li	a5,0
}
    80005380:	853e                	mv	a0,a5
    80005382:	60e2                	ld	ra,24(sp)
    80005384:	6442                	ld	s0,16(sp)
    80005386:	6105                	addi	sp,sp,32
    80005388:	8082                	ret

000000008000538a <sys_fstat>:
{
    8000538a:	1101                	addi	sp,sp,-32
    8000538c:	ec06                	sd	ra,24(sp)
    8000538e:	e822                	sd	s0,16(sp)
    80005390:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005392:	fe040593          	addi	a1,s0,-32
    80005396:	4505                	li	a0,1
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	854080e7          	jalr	-1964(ra) # 80002bec <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053a0:	fe840613          	addi	a2,s0,-24
    800053a4:	4581                	li	a1,0
    800053a6:	4501                	li	a0,0
    800053a8:	00000097          	auipc	ra,0x0
    800053ac:	c6e080e7          	jalr	-914(ra) # 80005016 <argfd>
    800053b0:	87aa                	mv	a5,a0
    return -1;
    800053b2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053b4:	0007ca63          	bltz	a5,800053c8 <sys_fstat+0x3e>
  return filestat(f, st);
    800053b8:	fe043583          	ld	a1,-32(s0)
    800053bc:	fe843503          	ld	a0,-24(s0)
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	2a0080e7          	jalr	672(ra) # 80004660 <filestat>
}
    800053c8:	60e2                	ld	ra,24(sp)
    800053ca:	6442                	ld	s0,16(sp)
    800053cc:	6105                	addi	sp,sp,32
    800053ce:	8082                	ret

00000000800053d0 <sys_link>:
{
    800053d0:	7169                	addi	sp,sp,-304
    800053d2:	f606                	sd	ra,296(sp)
    800053d4:	f222                	sd	s0,288(sp)
    800053d6:	ee26                	sd	s1,280(sp)
    800053d8:	ea4a                	sd	s2,272(sp)
    800053da:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053dc:	08000613          	li	a2,128
    800053e0:	ed040593          	addi	a1,s0,-304
    800053e4:	4501                	li	a0,0
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	826080e7          	jalr	-2010(ra) # 80002c0c <argstr>
    return -1;
    800053ee:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053f0:	10054e63          	bltz	a0,8000550c <sys_link+0x13c>
    800053f4:	08000613          	li	a2,128
    800053f8:	f5040593          	addi	a1,s0,-176
    800053fc:	4505                	li	a0,1
    800053fe:	ffffe097          	auipc	ra,0xffffe
    80005402:	80e080e7          	jalr	-2034(ra) # 80002c0c <argstr>
    return -1;
    80005406:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005408:	10054263          	bltz	a0,8000550c <sys_link+0x13c>
  begin_op();
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	cc8080e7          	jalr	-824(ra) # 800040d4 <begin_op>
  if((ip = namei(old)) == 0){
    80005414:	ed040513          	addi	a0,s0,-304
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	abc080e7          	jalr	-1348(ra) # 80003ed4 <namei>
    80005420:	84aa                	mv	s1,a0
    80005422:	c551                	beqz	a0,800054ae <sys_link+0xde>
  ilock(ip);
    80005424:	ffffe097          	auipc	ra,0xffffe
    80005428:	30a080e7          	jalr	778(ra) # 8000372e <ilock>
  if(ip->type == T_DIR){
    8000542c:	04449703          	lh	a4,68(s1)
    80005430:	4785                	li	a5,1
    80005432:	08f70463          	beq	a4,a5,800054ba <sys_link+0xea>
  ip->nlink++;
    80005436:	04a4d783          	lhu	a5,74(s1)
    8000543a:	2785                	addiw	a5,a5,1
    8000543c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005440:	8526                	mv	a0,s1
    80005442:	ffffe097          	auipc	ra,0xffffe
    80005446:	220080e7          	jalr	544(ra) # 80003662 <iupdate>
  iunlock(ip);
    8000544a:	8526                	mv	a0,s1
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	3a4080e7          	jalr	932(ra) # 800037f0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005454:	fd040593          	addi	a1,s0,-48
    80005458:	f5040513          	addi	a0,s0,-176
    8000545c:	fffff097          	auipc	ra,0xfffff
    80005460:	a96080e7          	jalr	-1386(ra) # 80003ef2 <nameiparent>
    80005464:	892a                	mv	s2,a0
    80005466:	c935                	beqz	a0,800054da <sys_link+0x10a>
  ilock(dp);
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	2c6080e7          	jalr	710(ra) # 8000372e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005470:	00092703          	lw	a4,0(s2)
    80005474:	409c                	lw	a5,0(s1)
    80005476:	04f71d63          	bne	a4,a5,800054d0 <sys_link+0x100>
    8000547a:	40d0                	lw	a2,4(s1)
    8000547c:	fd040593          	addi	a1,s0,-48
    80005480:	854a                	mv	a0,s2
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	9a0080e7          	jalr	-1632(ra) # 80003e22 <dirlink>
    8000548a:	04054363          	bltz	a0,800054d0 <sys_link+0x100>
  iunlockput(dp);
    8000548e:	854a                	mv	a0,s2
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	500080e7          	jalr	1280(ra) # 80003990 <iunlockput>
  iput(ip);
    80005498:	8526                	mv	a0,s1
    8000549a:	ffffe097          	auipc	ra,0xffffe
    8000549e:	44e080e7          	jalr	1102(ra) # 800038e8 <iput>
  end_op();
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	cac080e7          	jalr	-852(ra) # 8000414e <end_op>
  return 0;
    800054aa:	4781                	li	a5,0
    800054ac:	a085                	j	8000550c <sys_link+0x13c>
    end_op();
    800054ae:	fffff097          	auipc	ra,0xfffff
    800054b2:	ca0080e7          	jalr	-864(ra) # 8000414e <end_op>
    return -1;
    800054b6:	57fd                	li	a5,-1
    800054b8:	a891                	j	8000550c <sys_link+0x13c>
    iunlockput(ip);
    800054ba:	8526                	mv	a0,s1
    800054bc:	ffffe097          	auipc	ra,0xffffe
    800054c0:	4d4080e7          	jalr	1236(ra) # 80003990 <iunlockput>
    end_op();
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	c8a080e7          	jalr	-886(ra) # 8000414e <end_op>
    return -1;
    800054cc:	57fd                	li	a5,-1
    800054ce:	a83d                	j	8000550c <sys_link+0x13c>
    iunlockput(dp);
    800054d0:	854a                	mv	a0,s2
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	4be080e7          	jalr	1214(ra) # 80003990 <iunlockput>
  ilock(ip);
    800054da:	8526                	mv	a0,s1
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	252080e7          	jalr	594(ra) # 8000372e <ilock>
  ip->nlink--;
    800054e4:	04a4d783          	lhu	a5,74(s1)
    800054e8:	37fd                	addiw	a5,a5,-1
    800054ea:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ee:	8526                	mv	a0,s1
    800054f0:	ffffe097          	auipc	ra,0xffffe
    800054f4:	172080e7          	jalr	370(ra) # 80003662 <iupdate>
  iunlockput(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	496080e7          	jalr	1174(ra) # 80003990 <iunlockput>
  end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	c4c080e7          	jalr	-948(ra) # 8000414e <end_op>
  return -1;
    8000550a:	57fd                	li	a5,-1
}
    8000550c:	853e                	mv	a0,a5
    8000550e:	70b2                	ld	ra,296(sp)
    80005510:	7412                	ld	s0,288(sp)
    80005512:	64f2                	ld	s1,280(sp)
    80005514:	6952                	ld	s2,272(sp)
    80005516:	6155                	addi	sp,sp,304
    80005518:	8082                	ret

000000008000551a <sys_unlink>:
{
    8000551a:	7151                	addi	sp,sp,-240
    8000551c:	f586                	sd	ra,232(sp)
    8000551e:	f1a2                	sd	s0,224(sp)
    80005520:	eda6                	sd	s1,216(sp)
    80005522:	e9ca                	sd	s2,208(sp)
    80005524:	e5ce                	sd	s3,200(sp)
    80005526:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005528:	08000613          	li	a2,128
    8000552c:	f3040593          	addi	a1,s0,-208
    80005530:	4501                	li	a0,0
    80005532:	ffffd097          	auipc	ra,0xffffd
    80005536:	6da080e7          	jalr	1754(ra) # 80002c0c <argstr>
    8000553a:	18054163          	bltz	a0,800056bc <sys_unlink+0x1a2>
  begin_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	b96080e7          	jalr	-1130(ra) # 800040d4 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005546:	fb040593          	addi	a1,s0,-80
    8000554a:	f3040513          	addi	a0,s0,-208
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	9a4080e7          	jalr	-1628(ra) # 80003ef2 <nameiparent>
    80005556:	84aa                	mv	s1,a0
    80005558:	c979                	beqz	a0,8000562e <sys_unlink+0x114>
  ilock(dp);
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	1d4080e7          	jalr	468(ra) # 8000372e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005562:	00003597          	auipc	a1,0x3
    80005566:	20e58593          	addi	a1,a1,526 # 80008770 <syscalls+0x318>
    8000556a:	fb040513          	addi	a0,s0,-80
    8000556e:	ffffe097          	auipc	ra,0xffffe
    80005572:	68a080e7          	jalr	1674(ra) # 80003bf8 <namecmp>
    80005576:	14050a63          	beqz	a0,800056ca <sys_unlink+0x1b0>
    8000557a:	00003597          	auipc	a1,0x3
    8000557e:	1fe58593          	addi	a1,a1,510 # 80008778 <syscalls+0x320>
    80005582:	fb040513          	addi	a0,s0,-80
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	672080e7          	jalr	1650(ra) # 80003bf8 <namecmp>
    8000558e:	12050e63          	beqz	a0,800056ca <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005592:	f2c40613          	addi	a2,s0,-212
    80005596:	fb040593          	addi	a1,s0,-80
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	676080e7          	jalr	1654(ra) # 80003c12 <dirlookup>
    800055a4:	892a                	mv	s2,a0
    800055a6:	12050263          	beqz	a0,800056ca <sys_unlink+0x1b0>
  ilock(ip);
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	184080e7          	jalr	388(ra) # 8000372e <ilock>
  if(ip->nlink < 1)
    800055b2:	04a91783          	lh	a5,74(s2)
    800055b6:	08f05263          	blez	a5,8000563a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055ba:	04491703          	lh	a4,68(s2)
    800055be:	4785                	li	a5,1
    800055c0:	08f70563          	beq	a4,a5,8000564a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055c4:	4641                	li	a2,16
    800055c6:	4581                	li	a1,0
    800055c8:	fc040513          	addi	a0,s0,-64
    800055cc:	ffffb097          	auipc	ra,0xffffb
    800055d0:	778080e7          	jalr	1912(ra) # 80000d44 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055d4:	4741                	li	a4,16
    800055d6:	f2c42683          	lw	a3,-212(s0)
    800055da:	fc040613          	addi	a2,s0,-64
    800055de:	4581                	li	a1,0
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	4f8080e7          	jalr	1272(ra) # 80003ada <writei>
    800055ea:	47c1                	li	a5,16
    800055ec:	0af51563          	bne	a0,a5,80005696 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055f0:	04491703          	lh	a4,68(s2)
    800055f4:	4785                	li	a5,1
    800055f6:	0af70863          	beq	a4,a5,800056a6 <sys_unlink+0x18c>
  iunlockput(dp);
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffe097          	auipc	ra,0xffffe
    80005600:	394080e7          	jalr	916(ra) # 80003990 <iunlockput>
  ip->nlink--;
    80005604:	04a95783          	lhu	a5,74(s2)
    80005608:	37fd                	addiw	a5,a5,-1
    8000560a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000560e:	854a                	mv	a0,s2
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	052080e7          	jalr	82(ra) # 80003662 <iupdate>
  iunlockput(ip);
    80005618:	854a                	mv	a0,s2
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	376080e7          	jalr	886(ra) # 80003990 <iunlockput>
  end_op();
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	b2c080e7          	jalr	-1236(ra) # 8000414e <end_op>
  return 0;
    8000562a:	4501                	li	a0,0
    8000562c:	a84d                	j	800056de <sys_unlink+0x1c4>
    end_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	b20080e7          	jalr	-1248(ra) # 8000414e <end_op>
    return -1;
    80005636:	557d                	li	a0,-1
    80005638:	a05d                	j	800056de <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000563a:	00003517          	auipc	a0,0x3
    8000563e:	14650513          	addi	a0,a0,326 # 80008780 <syscalls+0x328>
    80005642:	ffffb097          	auipc	ra,0xffffb
    80005646:	efe080e7          	jalr	-258(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000564a:	04c92703          	lw	a4,76(s2)
    8000564e:	02000793          	li	a5,32
    80005652:	f6e7f9e3          	bgeu	a5,a4,800055c4 <sys_unlink+0xaa>
    80005656:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000565a:	4741                	li	a4,16
    8000565c:	86ce                	mv	a3,s3
    8000565e:	f1840613          	addi	a2,s0,-232
    80005662:	4581                	li	a1,0
    80005664:	854a                	mv	a0,s2
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	37c080e7          	jalr	892(ra) # 800039e2 <readi>
    8000566e:	47c1                	li	a5,16
    80005670:	00f51b63          	bne	a0,a5,80005686 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005674:	f1845783          	lhu	a5,-232(s0)
    80005678:	e7a1                	bnez	a5,800056c0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000567a:	29c1                	addiw	s3,s3,16
    8000567c:	04c92783          	lw	a5,76(s2)
    80005680:	fcf9ede3          	bltu	s3,a5,8000565a <sys_unlink+0x140>
    80005684:	b781                	j	800055c4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005686:	00003517          	auipc	a0,0x3
    8000568a:	11250513          	addi	a0,a0,274 # 80008798 <syscalls+0x340>
    8000568e:	ffffb097          	auipc	ra,0xffffb
    80005692:	eb2080e7          	jalr	-334(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005696:	00003517          	auipc	a0,0x3
    8000569a:	11a50513          	addi	a0,a0,282 # 800087b0 <syscalls+0x358>
    8000569e:	ffffb097          	auipc	ra,0xffffb
    800056a2:	ea2080e7          	jalr	-350(ra) # 80000540 <panic>
    dp->nlink--;
    800056a6:	04a4d783          	lhu	a5,74(s1)
    800056aa:	37fd                	addiw	a5,a5,-1
    800056ac:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	fb0080e7          	jalr	-80(ra) # 80003662 <iupdate>
    800056ba:	b781                	j	800055fa <sys_unlink+0xe0>
    return -1;
    800056bc:	557d                	li	a0,-1
    800056be:	a005                	j	800056de <sys_unlink+0x1c4>
    iunlockput(ip);
    800056c0:	854a                	mv	a0,s2
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	2ce080e7          	jalr	718(ra) # 80003990 <iunlockput>
  iunlockput(dp);
    800056ca:	8526                	mv	a0,s1
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	2c4080e7          	jalr	708(ra) # 80003990 <iunlockput>
  end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	a7a080e7          	jalr	-1414(ra) # 8000414e <end_op>
  return -1;
    800056dc:	557d                	li	a0,-1
}
    800056de:	70ae                	ld	ra,232(sp)
    800056e0:	740e                	ld	s0,224(sp)
    800056e2:	64ee                	ld	s1,216(sp)
    800056e4:	694e                	ld	s2,208(sp)
    800056e6:	69ae                	ld	s3,200(sp)
    800056e8:	616d                	addi	sp,sp,240
    800056ea:	8082                	ret

00000000800056ec <sys_open>:

uint64
sys_open(void)
{
    800056ec:	7131                	addi	sp,sp,-192
    800056ee:	fd06                	sd	ra,184(sp)
    800056f0:	f922                	sd	s0,176(sp)
    800056f2:	f526                	sd	s1,168(sp)
    800056f4:	f14a                	sd	s2,160(sp)
    800056f6:	ed4e                	sd	s3,152(sp)
    800056f8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800056fa:	f4c40593          	addi	a1,s0,-180
    800056fe:	4505                	li	a0,1
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	4cc080e7          	jalr	1228(ra) # 80002bcc <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005708:	08000613          	li	a2,128
    8000570c:	f5040593          	addi	a1,s0,-176
    80005710:	4501                	li	a0,0
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	4fa080e7          	jalr	1274(ra) # 80002c0c <argstr>
    8000571a:	87aa                	mv	a5,a0
    return -1;
    8000571c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000571e:	0a07c863          	bltz	a5,800057ce <sys_open+0xe2>

  begin_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	9b2080e7          	jalr	-1614(ra) # 800040d4 <begin_op>

  if(omode & O_CREATE){
    8000572a:	f4c42783          	lw	a5,-180(s0)
    8000572e:	2007f793          	andi	a5,a5,512
    80005732:	cbdd                	beqz	a5,800057e8 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005734:	4681                	li	a3,0
    80005736:	4601                	li	a2,0
    80005738:	4589                	li	a1,2
    8000573a:	f5040513          	addi	a0,s0,-176
    8000573e:	00000097          	auipc	ra,0x0
    80005742:	97a080e7          	jalr	-1670(ra) # 800050b8 <create>
    80005746:	84aa                	mv	s1,a0
    if(ip == 0){
    80005748:	c951                	beqz	a0,800057dc <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000574a:	04449703          	lh	a4,68(s1)
    8000574e:	478d                	li	a5,3
    80005750:	00f71763          	bne	a4,a5,8000575e <sys_open+0x72>
    80005754:	0464d703          	lhu	a4,70(s1)
    80005758:	47a5                	li	a5,9
    8000575a:	0ce7ec63          	bltu	a5,a4,80005832 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	d7e080e7          	jalr	-642(ra) # 800044dc <filealloc>
    80005766:	892a                	mv	s2,a0
    80005768:	c56d                	beqz	a0,80005852 <sys_open+0x166>
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	90c080e7          	jalr	-1780(ra) # 80005076 <fdalloc>
    80005772:	89aa                	mv	s3,a0
    80005774:	0c054a63          	bltz	a0,80005848 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005778:	04449703          	lh	a4,68(s1)
    8000577c:	478d                	li	a5,3
    8000577e:	0ef70563          	beq	a4,a5,80005868 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005782:	4789                	li	a5,2
    80005784:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005788:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000578c:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005790:	f4c42783          	lw	a5,-180(s0)
    80005794:	0017c713          	xori	a4,a5,1
    80005798:	8b05                	andi	a4,a4,1
    8000579a:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000579e:	0037f713          	andi	a4,a5,3
    800057a2:	00e03733          	snez	a4,a4
    800057a6:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057aa:	4007f793          	andi	a5,a5,1024
    800057ae:	c791                	beqz	a5,800057ba <sys_open+0xce>
    800057b0:	04449703          	lh	a4,68(s1)
    800057b4:	4789                	li	a5,2
    800057b6:	0cf70063          	beq	a4,a5,80005876 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	034080e7          	jalr	52(ra) # 800037f0 <iunlock>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	98a080e7          	jalr	-1654(ra) # 8000414e <end_op>

  return fd;
    800057cc:	854e                	mv	a0,s3
}
    800057ce:	70ea                	ld	ra,184(sp)
    800057d0:	744a                	ld	s0,176(sp)
    800057d2:	74aa                	ld	s1,168(sp)
    800057d4:	790a                	ld	s2,160(sp)
    800057d6:	69ea                	ld	s3,152(sp)
    800057d8:	6129                	addi	sp,sp,192
    800057da:	8082                	ret
      end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	972080e7          	jalr	-1678(ra) # 8000414e <end_op>
      return -1;
    800057e4:	557d                	li	a0,-1
    800057e6:	b7e5                	j	800057ce <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    800057e8:	f5040513          	addi	a0,s0,-176
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	6e8080e7          	jalr	1768(ra) # 80003ed4 <namei>
    800057f4:	84aa                	mv	s1,a0
    800057f6:	c905                	beqz	a0,80005826 <sys_open+0x13a>
    ilock(ip);
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	f36080e7          	jalr	-202(ra) # 8000372e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005800:	04449703          	lh	a4,68(s1)
    80005804:	4785                	li	a5,1
    80005806:	f4f712e3          	bne	a4,a5,8000574a <sys_open+0x5e>
    8000580a:	f4c42783          	lw	a5,-180(s0)
    8000580e:	dba1                	beqz	a5,8000575e <sys_open+0x72>
      iunlockput(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	17e080e7          	jalr	382(ra) # 80003990 <iunlockput>
      end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	934080e7          	jalr	-1740(ra) # 8000414e <end_op>
      return -1;
    80005822:	557d                	li	a0,-1
    80005824:	b76d                	j	800057ce <sys_open+0xe2>
      end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	928080e7          	jalr	-1752(ra) # 8000414e <end_op>
      return -1;
    8000582e:	557d                	li	a0,-1
    80005830:	bf79                	j	800057ce <sys_open+0xe2>
    iunlockput(ip);
    80005832:	8526                	mv	a0,s1
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	15c080e7          	jalr	348(ra) # 80003990 <iunlockput>
    end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	912080e7          	jalr	-1774(ra) # 8000414e <end_op>
    return -1;
    80005844:	557d                	li	a0,-1
    80005846:	b761                	j	800057ce <sys_open+0xe2>
      fileclose(f);
    80005848:	854a                	mv	a0,s2
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	d4e080e7          	jalr	-690(ra) # 80004598 <fileclose>
    iunlockput(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	13c080e7          	jalr	316(ra) # 80003990 <iunlockput>
    end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	8f2080e7          	jalr	-1806(ra) # 8000414e <end_op>
    return -1;
    80005864:	557d                	li	a0,-1
    80005866:	b7a5                	j	800057ce <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005868:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    8000586c:	04649783          	lh	a5,70(s1)
    80005870:	02f91223          	sh	a5,36(s2)
    80005874:	bf21                	j	8000578c <sys_open+0xa0>
    itrunc(ip);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	fc4080e7          	jalr	-60(ra) # 8000383c <itrunc>
    80005880:	bf2d                	j	800057ba <sys_open+0xce>

0000000080005882 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005882:	7175                	addi	sp,sp,-144
    80005884:	e506                	sd	ra,136(sp)
    80005886:	e122                	sd	s0,128(sp)
    80005888:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	84a080e7          	jalr	-1974(ra) # 800040d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005892:	08000613          	li	a2,128
    80005896:	f7040593          	addi	a1,s0,-144
    8000589a:	4501                	li	a0,0
    8000589c:	ffffd097          	auipc	ra,0xffffd
    800058a0:	370080e7          	jalr	880(ra) # 80002c0c <argstr>
    800058a4:	02054963          	bltz	a0,800058d6 <sys_mkdir+0x54>
    800058a8:	4681                	li	a3,0
    800058aa:	4601                	li	a2,0
    800058ac:	4585                	li	a1,1
    800058ae:	f7040513          	addi	a0,s0,-144
    800058b2:	00000097          	auipc	ra,0x0
    800058b6:	806080e7          	jalr	-2042(ra) # 800050b8 <create>
    800058ba:	cd11                	beqz	a0,800058d6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	0d4080e7          	jalr	212(ra) # 80003990 <iunlockput>
  end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	88a080e7          	jalr	-1910(ra) # 8000414e <end_op>
  return 0;
    800058cc:	4501                	li	a0,0
}
    800058ce:	60aa                	ld	ra,136(sp)
    800058d0:	640a                	ld	s0,128(sp)
    800058d2:	6149                	addi	sp,sp,144
    800058d4:	8082                	ret
    end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	878080e7          	jalr	-1928(ra) # 8000414e <end_op>
    return -1;
    800058de:	557d                	li	a0,-1
    800058e0:	b7fd                	j	800058ce <sys_mkdir+0x4c>

00000000800058e2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058e2:	7135                	addi	sp,sp,-160
    800058e4:	ed06                	sd	ra,152(sp)
    800058e6:	e922                	sd	s0,144(sp)
    800058e8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058ea:	ffffe097          	auipc	ra,0xffffe
    800058ee:	7ea080e7          	jalr	2026(ra) # 800040d4 <begin_op>
  argint(1, &major);
    800058f2:	f6c40593          	addi	a1,s0,-148
    800058f6:	4505                	li	a0,1
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	2d4080e7          	jalr	724(ra) # 80002bcc <argint>
  argint(2, &minor);
    80005900:	f6840593          	addi	a1,s0,-152
    80005904:	4509                	li	a0,2
    80005906:	ffffd097          	auipc	ra,0xffffd
    8000590a:	2c6080e7          	jalr	710(ra) # 80002bcc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000590e:	08000613          	li	a2,128
    80005912:	f7040593          	addi	a1,s0,-144
    80005916:	4501                	li	a0,0
    80005918:	ffffd097          	auipc	ra,0xffffd
    8000591c:	2f4080e7          	jalr	756(ra) # 80002c0c <argstr>
    80005920:	02054b63          	bltz	a0,80005956 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005924:	f6841683          	lh	a3,-152(s0)
    80005928:	f6c41603          	lh	a2,-148(s0)
    8000592c:	458d                	li	a1,3
    8000592e:	f7040513          	addi	a0,s0,-144
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	786080e7          	jalr	1926(ra) # 800050b8 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000593a:	cd11                	beqz	a0,80005956 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	054080e7          	jalr	84(ra) # 80003990 <iunlockput>
  end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	80a080e7          	jalr	-2038(ra) # 8000414e <end_op>
  return 0;
    8000594c:	4501                	li	a0,0
}
    8000594e:	60ea                	ld	ra,152(sp)
    80005950:	644a                	ld	s0,144(sp)
    80005952:	610d                	addi	sp,sp,160
    80005954:	8082                	ret
    end_op();
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	7f8080e7          	jalr	2040(ra) # 8000414e <end_op>
    return -1;
    8000595e:	557d                	li	a0,-1
    80005960:	b7fd                	j	8000594e <sys_mknod+0x6c>

0000000080005962 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005962:	7135                	addi	sp,sp,-160
    80005964:	ed06                	sd	ra,152(sp)
    80005966:	e922                	sd	s0,144(sp)
    80005968:	e526                	sd	s1,136(sp)
    8000596a:	e14a                	sd	s2,128(sp)
    8000596c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    8000596e:	ffffc097          	auipc	ra,0xffffc
    80005972:	0b6080e7          	jalr	182(ra) # 80001a24 <myproc>
    80005976:	892a                	mv	s2,a0
  
  begin_op();
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	75c080e7          	jalr	1884(ra) # 800040d4 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005980:	08000613          	li	a2,128
    80005984:	f6040593          	addi	a1,s0,-160
    80005988:	4501                	li	a0,0
    8000598a:	ffffd097          	auipc	ra,0xffffd
    8000598e:	282080e7          	jalr	642(ra) # 80002c0c <argstr>
    80005992:	04054b63          	bltz	a0,800059e8 <sys_chdir+0x86>
    80005996:	f6040513          	addi	a0,s0,-160
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	53a080e7          	jalr	1338(ra) # 80003ed4 <namei>
    800059a2:	84aa                	mv	s1,a0
    800059a4:	c131                	beqz	a0,800059e8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059a6:	ffffe097          	auipc	ra,0xffffe
    800059aa:	d88080e7          	jalr	-632(ra) # 8000372e <ilock>
  if(ip->type != T_DIR){
    800059ae:	04449703          	lh	a4,68(s1)
    800059b2:	4785                	li	a5,1
    800059b4:	04f71063          	bne	a4,a5,800059f4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059b8:	8526                	mv	a0,s1
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	e36080e7          	jalr	-458(ra) # 800037f0 <iunlock>
  iput(p->cwd);
    800059c2:	15093503          	ld	a0,336(s2)
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	f22080e7          	jalr	-222(ra) # 800038e8 <iput>
  end_op();
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	780080e7          	jalr	1920(ra) # 8000414e <end_op>
  p->cwd = ip;
    800059d6:	14993823          	sd	s1,336(s2)
  return 0;
    800059da:	4501                	li	a0,0
}
    800059dc:	60ea                	ld	ra,152(sp)
    800059de:	644a                	ld	s0,144(sp)
    800059e0:	64aa                	ld	s1,136(sp)
    800059e2:	690a                	ld	s2,128(sp)
    800059e4:	610d                	addi	sp,sp,160
    800059e6:	8082                	ret
    end_op();
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	766080e7          	jalr	1894(ra) # 8000414e <end_op>
    return -1;
    800059f0:	557d                	li	a0,-1
    800059f2:	b7ed                	j	800059dc <sys_chdir+0x7a>
    iunlockput(ip);
    800059f4:	8526                	mv	a0,s1
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	f9a080e7          	jalr	-102(ra) # 80003990 <iunlockput>
    end_op();
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	750080e7          	jalr	1872(ra) # 8000414e <end_op>
    return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	bfd1                	j	800059dc <sys_chdir+0x7a>

0000000080005a0a <sys_exec>:

uint64
sys_exec(void)
{
    80005a0a:	7121                	addi	sp,sp,-448
    80005a0c:	ff06                	sd	ra,440(sp)
    80005a0e:	fb22                	sd	s0,432(sp)
    80005a10:	f726                	sd	s1,424(sp)
    80005a12:	f34a                	sd	s2,416(sp)
    80005a14:	ef4e                	sd	s3,408(sp)
    80005a16:	eb52                	sd	s4,400(sp)
    80005a18:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a1a:	e4840593          	addi	a1,s0,-440
    80005a1e:	4505                	li	a0,1
    80005a20:	ffffd097          	auipc	ra,0xffffd
    80005a24:	1cc080e7          	jalr	460(ra) # 80002bec <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a28:	08000613          	li	a2,128
    80005a2c:	f5040593          	addi	a1,s0,-176
    80005a30:	4501                	li	a0,0
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	1da080e7          	jalr	474(ra) # 80002c0c <argstr>
    80005a3a:	87aa                	mv	a5,a0
    return -1;
    80005a3c:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a3e:	0c07c263          	bltz	a5,80005b02 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005a42:	10000613          	li	a2,256
    80005a46:	4581                	li	a1,0
    80005a48:	e5040513          	addi	a0,s0,-432
    80005a4c:	ffffb097          	auipc	ra,0xffffb
    80005a50:	2f8080e7          	jalr	760(ra) # 80000d44 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a54:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005a58:	89a6                	mv	s3,s1
    80005a5a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a5c:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a60:	00391513          	slli	a0,s2,0x3
    80005a64:	e4040593          	addi	a1,s0,-448
    80005a68:	e4843783          	ld	a5,-440(s0)
    80005a6c:	953e                	add	a0,a0,a5
    80005a6e:	ffffd097          	auipc	ra,0xffffd
    80005a72:	0c0080e7          	jalr	192(ra) # 80002b2e <fetchaddr>
    80005a76:	02054a63          	bltz	a0,80005aaa <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005a7a:	e4043783          	ld	a5,-448(s0)
    80005a7e:	c3b9                	beqz	a5,80005ac4 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a80:	ffffb097          	auipc	ra,0xffffb
    80005a84:	0d8080e7          	jalr	216(ra) # 80000b58 <kalloc>
    80005a88:	85aa                	mv	a1,a0
    80005a8a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a8e:	cd11                	beqz	a0,80005aaa <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a90:	6605                	lui	a2,0x1
    80005a92:	e4043503          	ld	a0,-448(s0)
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	0ea080e7          	jalr	234(ra) # 80002b80 <fetchstr>
    80005a9e:	00054663          	bltz	a0,80005aaa <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005aa2:	0905                	addi	s2,s2,1
    80005aa4:	09a1                	addi	s3,s3,8
    80005aa6:	fb491de3          	bne	s2,s4,80005a60 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aaa:	f5040913          	addi	s2,s0,-176
    80005aae:	6088                	ld	a0,0(s1)
    80005ab0:	c921                	beqz	a0,80005b00 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	fa8080e7          	jalr	-88(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aba:	04a1                	addi	s1,s1,8
    80005abc:	ff2499e3          	bne	s1,s2,80005aae <sys_exec+0xa4>
  return -1;
    80005ac0:	557d                	li	a0,-1
    80005ac2:	a081                	j	80005b02 <sys_exec+0xf8>
      argv[i] = 0;
    80005ac4:	0009079b          	sext.w	a5,s2
    80005ac8:	078e                	slli	a5,a5,0x3
    80005aca:	fd078793          	addi	a5,a5,-48
    80005ace:	97a2                	add	a5,a5,s0
    80005ad0:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005ad4:	e5040593          	addi	a1,s0,-432
    80005ad8:	f5040513          	addi	a0,s0,-176
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	132080e7          	jalr	306(ra) # 80004c0e <exec>
    80005ae4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae6:	f5040993          	addi	s3,s0,-176
    80005aea:	6088                	ld	a0,0(s1)
    80005aec:	c901                	beqz	a0,80005afc <sys_exec+0xf2>
    kfree(argv[i]);
    80005aee:	ffffb097          	auipc	ra,0xffffb
    80005af2:	f6c080e7          	jalr	-148(ra) # 80000a5a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af6:	04a1                	addi	s1,s1,8
    80005af8:	ff3499e3          	bne	s1,s3,80005aea <sys_exec+0xe0>
  return ret;
    80005afc:	854a                	mv	a0,s2
    80005afe:	a011                	j	80005b02 <sys_exec+0xf8>
  return -1;
    80005b00:	557d                	li	a0,-1
}
    80005b02:	70fa                	ld	ra,440(sp)
    80005b04:	745a                	ld	s0,432(sp)
    80005b06:	74ba                	ld	s1,424(sp)
    80005b08:	791a                	ld	s2,416(sp)
    80005b0a:	69fa                	ld	s3,408(sp)
    80005b0c:	6a5a                	ld	s4,400(sp)
    80005b0e:	6139                	addi	sp,sp,448
    80005b10:	8082                	ret

0000000080005b12 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b12:	7139                	addi	sp,sp,-64
    80005b14:	fc06                	sd	ra,56(sp)
    80005b16:	f822                	sd	s0,48(sp)
    80005b18:	f426                	sd	s1,40(sp)
    80005b1a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b1c:	ffffc097          	auipc	ra,0xffffc
    80005b20:	f08080e7          	jalr	-248(ra) # 80001a24 <myproc>
    80005b24:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b26:	fd840593          	addi	a1,s0,-40
    80005b2a:	4501                	li	a0,0
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	0c0080e7          	jalr	192(ra) # 80002bec <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b34:	fc840593          	addi	a1,s0,-56
    80005b38:	fd040513          	addi	a0,s0,-48
    80005b3c:	fffff097          	auipc	ra,0xfffff
    80005b40:	d88080e7          	jalr	-632(ra) # 800048c4 <pipealloc>
    return -1;
    80005b44:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b46:	0c054463          	bltz	a0,80005c0e <sys_pipe+0xfc>
  fd0 = -1;
    80005b4a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b4e:	fd043503          	ld	a0,-48(s0)
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	524080e7          	jalr	1316(ra) # 80005076 <fdalloc>
    80005b5a:	fca42223          	sw	a0,-60(s0)
    80005b5e:	08054b63          	bltz	a0,80005bf4 <sys_pipe+0xe2>
    80005b62:	fc843503          	ld	a0,-56(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	510080e7          	jalr	1296(ra) # 80005076 <fdalloc>
    80005b6e:	fca42023          	sw	a0,-64(s0)
    80005b72:	06054863          	bltz	a0,80005be2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b76:	4691                	li	a3,4
    80005b78:	fc440613          	addi	a2,s0,-60
    80005b7c:	fd843583          	ld	a1,-40(s0)
    80005b80:	68a8                	ld	a0,80(s1)
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	b62080e7          	jalr	-1182(ra) # 800016e4 <copyout>
    80005b8a:	02054063          	bltz	a0,80005baa <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005b8e:	4691                	li	a3,4
    80005b90:	fc040613          	addi	a2,s0,-64
    80005b94:	fd843583          	ld	a1,-40(s0)
    80005b98:	0591                	addi	a1,a1,4
    80005b9a:	68a8                	ld	a0,80(s1)
    80005b9c:	ffffc097          	auipc	ra,0xffffc
    80005ba0:	b48080e7          	jalr	-1208(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ba4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ba6:	06055463          	bgez	a0,80005c0e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005baa:	fc442783          	lw	a5,-60(s0)
    80005bae:	07e9                	addi	a5,a5,26
    80005bb0:	078e                	slli	a5,a5,0x3
    80005bb2:	97a6                	add	a5,a5,s1
    80005bb4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bb8:	fc042783          	lw	a5,-64(s0)
    80005bbc:	07e9                	addi	a5,a5,26
    80005bbe:	078e                	slli	a5,a5,0x3
    80005bc0:	94be                	add	s1,s1,a5
    80005bc2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005bc6:	fd043503          	ld	a0,-48(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	9ce080e7          	jalr	-1586(ra) # 80004598 <fileclose>
    fileclose(wf);
    80005bd2:	fc843503          	ld	a0,-56(s0)
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	9c2080e7          	jalr	-1598(ra) # 80004598 <fileclose>
    return -1;
    80005bde:	57fd                	li	a5,-1
    80005be0:	a03d                	j	80005c0e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005be2:	fc442783          	lw	a5,-60(s0)
    80005be6:	0007c763          	bltz	a5,80005bf4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005bea:	07e9                	addi	a5,a5,26
    80005bec:	078e                	slli	a5,a5,0x3
    80005bee:	97a6                	add	a5,a5,s1
    80005bf0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005bf4:	fd043503          	ld	a0,-48(s0)
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	9a0080e7          	jalr	-1632(ra) # 80004598 <fileclose>
    fileclose(wf);
    80005c00:	fc843503          	ld	a0,-56(s0)
    80005c04:	fffff097          	auipc	ra,0xfffff
    80005c08:	994080e7          	jalr	-1644(ra) # 80004598 <fileclose>
    return -1;
    80005c0c:	57fd                	li	a5,-1
}
    80005c0e:	853e                	mv	a0,a5
    80005c10:	70e2                	ld	ra,56(sp)
    80005c12:	7442                	ld	s0,48(sp)
    80005c14:	74a2                	ld	s1,40(sp)
    80005c16:	6121                	addi	sp,sp,64
    80005c18:	8082                	ret
    80005c1a:	0000                	unimp
    80005c1c:	0000                	unimp
	...

0000000080005c20 <kernelvec>:
    80005c20:	7111                	addi	sp,sp,-256
    80005c22:	e006                	sd	ra,0(sp)
    80005c24:	e40a                	sd	sp,8(sp)
    80005c26:	e80e                	sd	gp,16(sp)
    80005c28:	ec12                	sd	tp,24(sp)
    80005c2a:	f016                	sd	t0,32(sp)
    80005c2c:	f41a                	sd	t1,40(sp)
    80005c2e:	f81e                	sd	t2,48(sp)
    80005c30:	fc22                	sd	s0,56(sp)
    80005c32:	e0a6                	sd	s1,64(sp)
    80005c34:	e4aa                	sd	a0,72(sp)
    80005c36:	e8ae                	sd	a1,80(sp)
    80005c38:	ecb2                	sd	a2,88(sp)
    80005c3a:	f0b6                	sd	a3,96(sp)
    80005c3c:	f4ba                	sd	a4,104(sp)
    80005c3e:	f8be                	sd	a5,112(sp)
    80005c40:	fcc2                	sd	a6,120(sp)
    80005c42:	e146                	sd	a7,128(sp)
    80005c44:	e54a                	sd	s2,136(sp)
    80005c46:	e94e                	sd	s3,144(sp)
    80005c48:	ed52                	sd	s4,152(sp)
    80005c4a:	f156                	sd	s5,160(sp)
    80005c4c:	f55a                	sd	s6,168(sp)
    80005c4e:	f95e                	sd	s7,176(sp)
    80005c50:	fd62                	sd	s8,184(sp)
    80005c52:	e1e6                	sd	s9,192(sp)
    80005c54:	e5ea                	sd	s10,200(sp)
    80005c56:	e9ee                	sd	s11,208(sp)
    80005c58:	edf2                	sd	t3,216(sp)
    80005c5a:	f1f6                	sd	t4,224(sp)
    80005c5c:	f5fa                	sd	t5,232(sp)
    80005c5e:	f9fe                	sd	t6,240(sp)
    80005c60:	d9bfc0ef          	jal	ra,800029fa <kerneltrap>
    80005c64:	6082                	ld	ra,0(sp)
    80005c66:	6122                	ld	sp,8(sp)
    80005c68:	61c2                	ld	gp,16(sp)
    80005c6a:	7282                	ld	t0,32(sp)
    80005c6c:	7322                	ld	t1,40(sp)
    80005c6e:	73c2                	ld	t2,48(sp)
    80005c70:	7462                	ld	s0,56(sp)
    80005c72:	6486                	ld	s1,64(sp)
    80005c74:	6526                	ld	a0,72(sp)
    80005c76:	65c6                	ld	a1,80(sp)
    80005c78:	6666                	ld	a2,88(sp)
    80005c7a:	7686                	ld	a3,96(sp)
    80005c7c:	7726                	ld	a4,104(sp)
    80005c7e:	77c6                	ld	a5,112(sp)
    80005c80:	7866                	ld	a6,120(sp)
    80005c82:	688a                	ld	a7,128(sp)
    80005c84:	692a                	ld	s2,136(sp)
    80005c86:	69ca                	ld	s3,144(sp)
    80005c88:	6a6a                	ld	s4,152(sp)
    80005c8a:	7a8a                	ld	s5,160(sp)
    80005c8c:	7b2a                	ld	s6,168(sp)
    80005c8e:	7bca                	ld	s7,176(sp)
    80005c90:	7c6a                	ld	s8,184(sp)
    80005c92:	6c8e                	ld	s9,192(sp)
    80005c94:	6d2e                	ld	s10,200(sp)
    80005c96:	6dce                	ld	s11,208(sp)
    80005c98:	6e6e                	ld	t3,216(sp)
    80005c9a:	7e8e                	ld	t4,224(sp)
    80005c9c:	7f2e                	ld	t5,232(sp)
    80005c9e:	7fce                	ld	t6,240(sp)
    80005ca0:	6111                	addi	sp,sp,256
    80005ca2:	10200073          	sret
    80005ca6:	00000013          	nop
    80005caa:	00000013          	nop
    80005cae:	0001                	nop

0000000080005cb0 <timervec>:
    80005cb0:	34051573          	csrrw	a0,mscratch,a0
    80005cb4:	e10c                	sd	a1,0(a0)
    80005cb6:	e510                	sd	a2,8(a0)
    80005cb8:	e914                	sd	a3,16(a0)
    80005cba:	6d0c                	ld	a1,24(a0)
    80005cbc:	7110                	ld	a2,32(a0)
    80005cbe:	6194                	ld	a3,0(a1)
    80005cc0:	96b2                	add	a3,a3,a2
    80005cc2:	e194                	sd	a3,0(a1)
    80005cc4:	4589                	li	a1,2
    80005cc6:	14459073          	csrw	sip,a1
    80005cca:	6914                	ld	a3,16(a0)
    80005ccc:	6510                	ld	a2,8(a0)
    80005cce:	610c                	ld	a1,0(a0)
    80005cd0:	34051573          	csrrw	a0,mscratch,a0
    80005cd4:	30200073          	mret
	...

0000000080005cda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cda:	1141                	addi	sp,sp,-16
    80005cdc:	e422                	sd	s0,8(sp)
    80005cde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ce0:	0c0007b7          	lui	a5,0xc000
    80005ce4:	4705                	li	a4,1
    80005ce6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ce8:	c3d8                	sw	a4,4(a5)
}
    80005cea:	6422                	ld	s0,8(sp)
    80005cec:	0141                	addi	sp,sp,16
    80005cee:	8082                	ret

0000000080005cf0 <plicinithart>:

void
plicinithart(void)
{
    80005cf0:	1141                	addi	sp,sp,-16
    80005cf2:	e406                	sd	ra,8(sp)
    80005cf4:	e022                	sd	s0,0(sp)
    80005cf6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005cf8:	ffffc097          	auipc	ra,0xffffc
    80005cfc:	d00080e7          	jalr	-768(ra) # 800019f8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d00:	0085171b          	slliw	a4,a0,0x8
    80005d04:	0c0027b7          	lui	a5,0xc002
    80005d08:	97ba                	add	a5,a5,a4
    80005d0a:	40200713          	li	a4,1026
    80005d0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d12:	00d5151b          	slliw	a0,a0,0xd
    80005d16:	0c2017b7          	lui	a5,0xc201
    80005d1a:	97aa                	add	a5,a5,a0
    80005d1c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d20:	60a2                	ld	ra,8(sp)
    80005d22:	6402                	ld	s0,0(sp)
    80005d24:	0141                	addi	sp,sp,16
    80005d26:	8082                	ret

0000000080005d28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d28:	1141                	addi	sp,sp,-16
    80005d2a:	e406                	sd	ra,8(sp)
    80005d2c:	e022                	sd	s0,0(sp)
    80005d2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d30:	ffffc097          	auipc	ra,0xffffc
    80005d34:	cc8080e7          	jalr	-824(ra) # 800019f8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d38:	00d5151b          	slliw	a0,a0,0xd
    80005d3c:	0c2017b7          	lui	a5,0xc201
    80005d40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d42:	43c8                	lw	a0,4(a5)
    80005d44:	60a2                	ld	ra,8(sp)
    80005d46:	6402                	ld	s0,0(sp)
    80005d48:	0141                	addi	sp,sp,16
    80005d4a:	8082                	ret

0000000080005d4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d4c:	1101                	addi	sp,sp,-32
    80005d4e:	ec06                	sd	ra,24(sp)
    80005d50:	e822                	sd	s0,16(sp)
    80005d52:	e426                	sd	s1,8(sp)
    80005d54:	1000                	addi	s0,sp,32
    80005d56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d58:	ffffc097          	auipc	ra,0xffffc
    80005d5c:	ca0080e7          	jalr	-864(ra) # 800019f8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d60:	00d5151b          	slliw	a0,a0,0xd
    80005d64:	0c2017b7          	lui	a5,0xc201
    80005d68:	97aa                	add	a5,a5,a0
    80005d6a:	c3c4                	sw	s1,4(a5)
}
    80005d6c:	60e2                	ld	ra,24(sp)
    80005d6e:	6442                	ld	s0,16(sp)
    80005d70:	64a2                	ld	s1,8(sp)
    80005d72:	6105                	addi	sp,sp,32
    80005d74:	8082                	ret

0000000080005d76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d76:	1141                	addi	sp,sp,-16
    80005d78:	e406                	sd	ra,8(sp)
    80005d7a:	e022                	sd	s0,0(sp)
    80005d7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d7e:	479d                	li	a5,7
    80005d80:	04a7cc63          	blt	a5,a0,80005dd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005d84:	0001c797          	auipc	a5,0x1c
    80005d88:	7dc78793          	addi	a5,a5,2012 # 80022560 <disk>
    80005d8c:	97aa                	add	a5,a5,a0
    80005d8e:	0187c783          	lbu	a5,24(a5)
    80005d92:	ebb9                	bnez	a5,80005de8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005d94:	00451693          	slli	a3,a0,0x4
    80005d98:	0001c797          	auipc	a5,0x1c
    80005d9c:	7c878793          	addi	a5,a5,1992 # 80022560 <disk>
    80005da0:	6398                	ld	a4,0(a5)
    80005da2:	9736                	add	a4,a4,a3
    80005da4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005da8:	6398                	ld	a4,0(a5)
    80005daa:	9736                	add	a4,a4,a3
    80005dac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005db0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005db4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	4705                	li	a4,1
    80005dbc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005dc0:	0001c517          	auipc	a0,0x1c
    80005dc4:	7b850513          	addi	a0,a0,1976 # 80022578 <disk+0x18>
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	396080e7          	jalr	918(ra) # 8000215e <wakeup>
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret
    panic("free_desc 1");
    80005dd8:	00003517          	auipc	a0,0x3
    80005ddc:	9e850513          	addi	a0,a0,-1560 # 800087c0 <syscalls+0x368>
    80005de0:	ffffa097          	auipc	ra,0xffffa
    80005de4:	760080e7          	jalr	1888(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	9e850513          	addi	a0,a0,-1560 # 800087d0 <syscalls+0x378>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	750080e7          	jalr	1872(ra) # 80000540 <panic>

0000000080005df8 <virtio_disk_init>:
{
    80005df8:	1101                	addi	sp,sp,-32
    80005dfa:	ec06                	sd	ra,24(sp)
    80005dfc:	e822                	sd	s0,16(sp)
    80005dfe:	e426                	sd	s1,8(sp)
    80005e00:	e04a                	sd	s2,0(sp)
    80005e02:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e04:	00003597          	auipc	a1,0x3
    80005e08:	9dc58593          	addi	a1,a1,-1572 # 800087e0 <syscalls+0x388>
    80005e0c:	0001d517          	auipc	a0,0x1d
    80005e10:	87c50513          	addi	a0,a0,-1924 # 80022688 <disk+0x128>
    80005e14:	ffffb097          	auipc	ra,0xffffb
    80005e18:	da4080e7          	jalr	-604(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e1c:	100017b7          	lui	a5,0x10001
    80005e20:	4398                	lw	a4,0(a5)
    80005e22:	2701                	sext.w	a4,a4
    80005e24:	747277b7          	lui	a5,0x74727
    80005e28:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e2c:	14f71b63          	bne	a4,a5,80005f82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e30:	100017b7          	lui	a5,0x10001
    80005e34:	43dc                	lw	a5,4(a5)
    80005e36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e38:	4709                	li	a4,2
    80005e3a:	14e79463          	bne	a5,a4,80005f82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	479c                	lw	a5,8(a5)
    80005e44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e46:	12e79e63          	bne	a5,a4,80005f82 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e4a:	100017b7          	lui	a5,0x10001
    80005e4e:	47d8                	lw	a4,12(a5)
    80005e50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e52:	554d47b7          	lui	a5,0x554d4
    80005e56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e5a:	12f71463          	bne	a4,a5,80005f82 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e5e:	100017b7          	lui	a5,0x10001
    80005e62:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e66:	4705                	li	a4,1
    80005e68:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6a:	470d                	li	a4,3
    80005e6c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e6e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e70:	c7ffe6b7          	lui	a3,0xc7ffe
    80005e74:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbe1f>
    80005e78:	8f75                	and	a4,a4,a3
    80005e7a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e7c:	472d                	li	a4,11
    80005e7e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005e80:	5bbc                	lw	a5,112(a5)
    80005e82:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005e86:	8ba1                	andi	a5,a5,8
    80005e88:	10078563          	beqz	a5,80005f92 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005e94:	43fc                	lw	a5,68(a5)
    80005e96:	2781                	sext.w	a5,a5
    80005e98:	10079563          	bnez	a5,80005fa2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e9c:	100017b7          	lui	a5,0x10001
    80005ea0:	5bdc                	lw	a5,52(a5)
    80005ea2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ea4:	10078763          	beqz	a5,80005fb2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005ea8:	471d                	li	a4,7
    80005eaa:	10f77c63          	bgeu	a4,a5,80005fc2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005eae:	ffffb097          	auipc	ra,0xffffb
    80005eb2:	caa080e7          	jalr	-854(ra) # 80000b58 <kalloc>
    80005eb6:	0001c497          	auipc	s1,0x1c
    80005eba:	6aa48493          	addi	s1,s1,1706 # 80022560 <disk>
    80005ebe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ec0:	ffffb097          	auipc	ra,0xffffb
    80005ec4:	c98080e7          	jalr	-872(ra) # 80000b58 <kalloc>
    80005ec8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005eca:	ffffb097          	auipc	ra,0xffffb
    80005ece:	c8e080e7          	jalr	-882(ra) # 80000b58 <kalloc>
    80005ed2:	87aa                	mv	a5,a0
    80005ed4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005ed6:	6088                	ld	a0,0(s1)
    80005ed8:	cd6d                	beqz	a0,80005fd2 <virtio_disk_init+0x1da>
    80005eda:	0001c717          	auipc	a4,0x1c
    80005ede:	68e73703          	ld	a4,1678(a4) # 80022568 <disk+0x8>
    80005ee2:	cb65                	beqz	a4,80005fd2 <virtio_disk_init+0x1da>
    80005ee4:	c7fd                	beqz	a5,80005fd2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005ee6:	6605                	lui	a2,0x1
    80005ee8:	4581                	li	a1,0
    80005eea:	ffffb097          	auipc	ra,0xffffb
    80005eee:	e5a080e7          	jalr	-422(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005ef2:	0001c497          	auipc	s1,0x1c
    80005ef6:	66e48493          	addi	s1,s1,1646 # 80022560 <disk>
    80005efa:	6605                	lui	a2,0x1
    80005efc:	4581                	li	a1,0
    80005efe:	6488                	ld	a0,8(s1)
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	e44080e7          	jalr	-444(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f08:	6605                	lui	a2,0x1
    80005f0a:	4581                	li	a1,0
    80005f0c:	6888                	ld	a0,16(s1)
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	e36080e7          	jalr	-458(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f16:	100017b7          	lui	a5,0x10001
    80005f1a:	4721                	li	a4,8
    80005f1c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f1e:	4098                	lw	a4,0(s1)
    80005f20:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f24:	40d8                	lw	a4,4(s1)
    80005f26:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f2a:	6498                	ld	a4,8(s1)
    80005f2c:	0007069b          	sext.w	a3,a4
    80005f30:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f34:	9701                	srai	a4,a4,0x20
    80005f36:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f3a:	6898                	ld	a4,16(s1)
    80005f3c:	0007069b          	sext.w	a3,a4
    80005f40:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f44:	9701                	srai	a4,a4,0x20
    80005f46:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f4a:	4705                	li	a4,1
    80005f4c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f4e:	00e48c23          	sb	a4,24(s1)
    80005f52:	00e48ca3          	sb	a4,25(s1)
    80005f56:	00e48d23          	sb	a4,26(s1)
    80005f5a:	00e48da3          	sb	a4,27(s1)
    80005f5e:	00e48e23          	sb	a4,28(s1)
    80005f62:	00e48ea3          	sb	a4,29(s1)
    80005f66:	00e48f23          	sb	a4,30(s1)
    80005f6a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005f6e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f72:	0727a823          	sw	s2,112(a5)
}
    80005f76:	60e2                	ld	ra,24(sp)
    80005f78:	6442                	ld	s0,16(sp)
    80005f7a:	64a2                	ld	s1,8(sp)
    80005f7c:	6902                	ld	s2,0(sp)
    80005f7e:	6105                	addi	sp,sp,32
    80005f80:	8082                	ret
    panic("could not find virtio disk");
    80005f82:	00003517          	auipc	a0,0x3
    80005f86:	86e50513          	addi	a0,a0,-1938 # 800087f0 <syscalls+0x398>
    80005f8a:	ffffa097          	auipc	ra,0xffffa
    80005f8e:	5b6080e7          	jalr	1462(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005f92:	00003517          	auipc	a0,0x3
    80005f96:	87e50513          	addi	a0,a0,-1922 # 80008810 <syscalls+0x3b8>
    80005f9a:	ffffa097          	auipc	ra,0xffffa
    80005f9e:	5a6080e7          	jalr	1446(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fa2:	00003517          	auipc	a0,0x3
    80005fa6:	88e50513          	addi	a0,a0,-1906 # 80008830 <syscalls+0x3d8>
    80005faa:	ffffa097          	auipc	ra,0xffffa
    80005fae:	596080e7          	jalr	1430(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005fb2:	00003517          	auipc	a0,0x3
    80005fb6:	89e50513          	addi	a0,a0,-1890 # 80008850 <syscalls+0x3f8>
    80005fba:	ffffa097          	auipc	ra,0xffffa
    80005fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	8ae50513          	addi	a0,a0,-1874 # 80008870 <syscalls+0x418>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80005fd2:	00003517          	auipc	a0,0x3
    80005fd6:	8be50513          	addi	a0,a0,-1858 # 80008890 <syscalls+0x438>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>

0000000080005fe2 <virtio_disk_init_bootloader>:
{
    80005fe2:	1101                	addi	sp,sp,-32
    80005fe4:	ec06                	sd	ra,24(sp)
    80005fe6:	e822                	sd	s0,16(sp)
    80005fe8:	e426                	sd	s1,8(sp)
    80005fea:	e04a                	sd	s2,0(sp)
    80005fec:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fee:	00002597          	auipc	a1,0x2
    80005ff2:	7f258593          	addi	a1,a1,2034 # 800087e0 <syscalls+0x388>
    80005ff6:	0001c517          	auipc	a0,0x1c
    80005ffa:	69250513          	addi	a0,a0,1682 # 80022688 <disk+0x128>
    80005ffe:	ffffb097          	auipc	ra,0xffffb
    80006002:	bba080e7          	jalr	-1094(ra) # 80000bb8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006006:	100017b7          	lui	a5,0x10001
    8000600a:	4398                	lw	a4,0(a5)
    8000600c:	2701                	sext.w	a4,a4
    8000600e:	747277b7          	lui	a5,0x74727
    80006012:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006016:	12f71763          	bne	a4,a5,80006144 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	43dc                	lw	a5,4(a5)
    80006020:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006022:	4709                	li	a4,2
    80006024:	12e79063          	bne	a5,a4,80006144 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006028:	100017b7          	lui	a5,0x10001
    8000602c:	479c                	lw	a5,8(a5)
    8000602e:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006030:	10e79a63          	bne	a5,a4,80006144 <virtio_disk_init_bootloader+0x162>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006034:	100017b7          	lui	a5,0x10001
    80006038:	47d8                	lw	a4,12(a5)
    8000603a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603c:	554d47b7          	lui	a5,0x554d4
    80006040:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006044:	10f71063          	bne	a4,a5,80006144 <virtio_disk_init_bootloader+0x162>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006048:	100017b7          	lui	a5,0x10001
    8000604c:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006050:	4705                	li	a4,1
    80006052:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006054:	470d                	li	a4,3
    80006056:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006058:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000605a:	c7ffe6b7          	lui	a3,0xc7ffe
    8000605e:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbe1f>
    80006062:	8f75                	and	a4,a4,a3
    80006064:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	472d                	li	a4,11
    80006068:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    8000606a:	5bbc                	lw	a5,112(a5)
    8000606c:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006070:	8ba1                	andi	a5,a5,8
    80006072:	c3ed                	beqz	a5,80006154 <virtio_disk_init_bootloader+0x172>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006074:	100017b7          	lui	a5,0x10001
    80006078:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000607c:	43fc                	lw	a5,68(a5)
    8000607e:	2781                	sext.w	a5,a5
    80006080:	e3f5                	bnez	a5,80006164 <virtio_disk_init_bootloader+0x182>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006082:	100017b7          	lui	a5,0x10001
    80006086:	5bdc                	lw	a5,52(a5)
    80006088:	2781                	sext.w	a5,a5
  if(max == 0)
    8000608a:	c7ed                	beqz	a5,80006174 <virtio_disk_init_bootloader+0x192>
  if(max < NUM)
    8000608c:	471d                	li	a4,7
    8000608e:	0ef77b63          	bgeu	a4,a5,80006184 <virtio_disk_init_bootloader+0x1a2>
  disk.desc  = (void*) 0x77000000;
    80006092:	0001c497          	auipc	s1,0x1c
    80006096:	4ce48493          	addi	s1,s1,1230 # 80022560 <disk>
    8000609a:	770007b7          	lui	a5,0x77000
    8000609e:	e09c                	sd	a5,0(s1)
  disk.avail = (void*) 0x77001000;
    800060a0:	770017b7          	lui	a5,0x77001
    800060a4:	e49c                	sd	a5,8(s1)
  disk.used  = (void*) 0x77002000;
    800060a6:	770027b7          	lui	a5,0x77002
    800060aa:	e89c                	sd	a5,16(s1)
  memset(disk.desc, 0, PGSIZE);
    800060ac:	6605                	lui	a2,0x1
    800060ae:	4581                	li	a1,0
    800060b0:	77000537          	lui	a0,0x77000
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	c90080e7          	jalr	-880(ra) # 80000d44 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060bc:	6605                	lui	a2,0x1
    800060be:	4581                	li	a1,0
    800060c0:	6488                	ld	a0,8(s1)
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	c82080e7          	jalr	-894(ra) # 80000d44 <memset>
  memset(disk.used, 0, PGSIZE);
    800060ca:	6605                	lui	a2,0x1
    800060cc:	4581                	li	a1,0
    800060ce:	6888                	ld	a0,16(s1)
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	c74080e7          	jalr	-908(ra) # 80000d44 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060d8:	100017b7          	lui	a5,0x10001
    800060dc:	4721                	li	a4,8
    800060de:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060e0:	4098                	lw	a4,0(s1)
    800060e2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060e6:	40d8                	lw	a4,4(s1)
    800060e8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060ec:	6498                	ld	a4,8(s1)
    800060ee:	0007069b          	sext.w	a3,a4
    800060f2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060f6:	9701                	srai	a4,a4,0x20
    800060f8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060fc:	6898                	ld	a4,16(s1)
    800060fe:	0007069b          	sext.w	a3,a4
    80006102:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006106:	9701                	srai	a4,a4,0x20
    80006108:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000610c:	4705                	li	a4,1
    8000610e:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006110:	00e48c23          	sb	a4,24(s1)
    80006114:	00e48ca3          	sb	a4,25(s1)
    80006118:	00e48d23          	sb	a4,26(s1)
    8000611c:	00e48da3          	sb	a4,27(s1)
    80006120:	00e48e23          	sb	a4,28(s1)
    80006124:	00e48ea3          	sb	a4,29(s1)
    80006128:	00e48f23          	sb	a4,30(s1)
    8000612c:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006130:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006134:	0727a823          	sw	s2,112(a5)
}
    80006138:	60e2                	ld	ra,24(sp)
    8000613a:	6442                	ld	s0,16(sp)
    8000613c:	64a2                	ld	s1,8(sp)
    8000613e:	6902                	ld	s2,0(sp)
    80006140:	6105                	addi	sp,sp,32
    80006142:	8082                	ret
    panic("could not find virtio disk");
    80006144:	00002517          	auipc	a0,0x2
    80006148:	6ac50513          	addi	a0,a0,1708 # 800087f0 <syscalls+0x398>
    8000614c:	ffffa097          	auipc	ra,0xffffa
    80006150:	3f4080e7          	jalr	1012(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006154:	00002517          	auipc	a0,0x2
    80006158:	6bc50513          	addi	a0,a0,1724 # 80008810 <syscalls+0x3b8>
    8000615c:	ffffa097          	auipc	ra,0xffffa
    80006160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006164:	00002517          	auipc	a0,0x2
    80006168:	6cc50513          	addi	a0,a0,1740 # 80008830 <syscalls+0x3d8>
    8000616c:	ffffa097          	auipc	ra,0xffffa
    80006170:	3d4080e7          	jalr	980(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006174:	00002517          	auipc	a0,0x2
    80006178:	6dc50513          	addi	a0,a0,1756 # 80008850 <syscalls+0x3f8>
    8000617c:	ffffa097          	auipc	ra,0xffffa
    80006180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006184:	00002517          	auipc	a0,0x2
    80006188:	6ec50513          	addi	a0,a0,1772 # 80008870 <syscalls+0x418>
    8000618c:	ffffa097          	auipc	ra,0xffffa
    80006190:	3b4080e7          	jalr	948(ra) # 80000540 <panic>

0000000080006194 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006194:	7159                	addi	sp,sp,-112
    80006196:	f486                	sd	ra,104(sp)
    80006198:	f0a2                	sd	s0,96(sp)
    8000619a:	eca6                	sd	s1,88(sp)
    8000619c:	e8ca                	sd	s2,80(sp)
    8000619e:	e4ce                	sd	s3,72(sp)
    800061a0:	e0d2                	sd	s4,64(sp)
    800061a2:	fc56                	sd	s5,56(sp)
    800061a4:	f85a                	sd	s6,48(sp)
    800061a6:	f45e                	sd	s7,40(sp)
    800061a8:	f062                	sd	s8,32(sp)
    800061aa:	ec66                	sd	s9,24(sp)
    800061ac:	e86a                	sd	s10,16(sp)
    800061ae:	1880                	addi	s0,sp,112
    800061b0:	8a2a                	mv	s4,a0
    800061b2:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061b4:	00c52c83          	lw	s9,12(a0)
    800061b8:	001c9c9b          	slliw	s9,s9,0x1
    800061bc:	1c82                	slli	s9,s9,0x20
    800061be:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061c2:	0001c517          	auipc	a0,0x1c
    800061c6:	4c650513          	addi	a0,a0,1222 # 80022688 <disk+0x128>
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	a7e080e7          	jalr	-1410(ra) # 80000c48 <acquire>
  for(int i = 0; i < 3; i++){
    800061d2:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    800061d4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800061d6:	0001cb17          	auipc	s6,0x1c
    800061da:	38ab0b13          	addi	s6,s6,906 # 80022560 <disk>
  for(int i = 0; i < 3; i++){
    800061de:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061e0:	0001cc17          	auipc	s8,0x1c
    800061e4:	4a8c0c13          	addi	s8,s8,1192 # 80022688 <disk+0x128>
    800061e8:	a095                	j	8000624c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800061ea:	00fb0733          	add	a4,s6,a5
    800061ee:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800061f2:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800061f4:	0207c563          	bltz	a5,8000621e <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800061f8:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800061fa:	0591                	addi	a1,a1,4
    800061fc:	05560d63          	beq	a2,s5,80006256 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006200:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006202:	0001c717          	auipc	a4,0x1c
    80006206:	35e70713          	addi	a4,a4,862 # 80022560 <disk>
    8000620a:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000620c:	01874683          	lbu	a3,24(a4)
    80006210:	fee9                	bnez	a3,800061ea <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006212:	2785                	addiw	a5,a5,1
    80006214:	0705                	addi	a4,a4,1
    80006216:	fe979be3          	bne	a5,s1,8000620c <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    8000621a:	57fd                	li	a5,-1
    8000621c:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000621e:	00c05e63          	blez	a2,8000623a <virtio_disk_rw+0xa6>
    80006222:	060a                	slli	a2,a2,0x2
    80006224:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006228:	0009a503          	lw	a0,0(s3)
    8000622c:	00000097          	auipc	ra,0x0
    80006230:	b4a080e7          	jalr	-1206(ra) # 80005d76 <free_desc>
      for(int j = 0; j < i; j++)
    80006234:	0991                	addi	s3,s3,4
    80006236:	ffa999e3          	bne	s3,s10,80006228 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000623a:	85e2                	mv	a1,s8
    8000623c:	0001c517          	auipc	a0,0x1c
    80006240:	33c50513          	addi	a0,a0,828 # 80022578 <disk+0x18>
    80006244:	ffffc097          	auipc	ra,0xffffc
    80006248:	eb6080e7          	jalr	-330(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000624c:	f9040993          	addi	s3,s0,-112
{
    80006250:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006252:	864a                	mv	a2,s2
    80006254:	b775                	j	80006200 <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006256:	f9042503          	lw	a0,-112(s0)
    8000625a:	00a50713          	addi	a4,a0,10
    8000625e:	0712                	slli	a4,a4,0x4

  if(write)
    80006260:	0001c797          	auipc	a5,0x1c
    80006264:	30078793          	addi	a5,a5,768 # 80022560 <disk>
    80006268:	00e786b3          	add	a3,a5,a4
    8000626c:	01703633          	snez	a2,s7
    80006270:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006272:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006276:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000627a:	f6070613          	addi	a2,a4,-160
    8000627e:	6394                	ld	a3,0(a5)
    80006280:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006282:	00870593          	addi	a1,a4,8
    80006286:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006288:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000628a:	0007b803          	ld	a6,0(a5)
    8000628e:	9642                	add	a2,a2,a6
    80006290:	46c1                	li	a3,16
    80006292:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006294:	4585                	li	a1,1
    80006296:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    8000629a:	f9442683          	lw	a3,-108(s0)
    8000629e:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062a2:	0692                	slli	a3,a3,0x4
    800062a4:	9836                	add	a6,a6,a3
    800062a6:	058a0613          	addi	a2,s4,88
    800062aa:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800062ae:	0007b803          	ld	a6,0(a5)
    800062b2:	96c2                	add	a3,a3,a6
    800062b4:	40000613          	li	a2,1024
    800062b8:	c690                	sw	a2,8(a3)
  if(write)
    800062ba:	001bb613          	seqz	a2,s7
    800062be:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062c2:	00166613          	ori	a2,a2,1
    800062c6:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062ca:	f9842603          	lw	a2,-104(s0)
    800062ce:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062d2:	00250693          	addi	a3,a0,2
    800062d6:	0692                	slli	a3,a3,0x4
    800062d8:	96be                	add	a3,a3,a5
    800062da:	58fd                	li	a7,-1
    800062dc:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062e0:	0612                	slli	a2,a2,0x4
    800062e2:	9832                	add	a6,a6,a2
    800062e4:	f9070713          	addi	a4,a4,-112
    800062e8:	973e                	add	a4,a4,a5
    800062ea:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800062ee:	6398                	ld	a4,0(a5)
    800062f0:	9732                	add	a4,a4,a2
    800062f2:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062f4:	4609                	li	a2,2
    800062f6:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800062fa:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062fe:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006302:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006306:	6794                	ld	a3,8(a5)
    80006308:	0026d703          	lhu	a4,2(a3)
    8000630c:	8b1d                	andi	a4,a4,7
    8000630e:	0706                	slli	a4,a4,0x1
    80006310:	96ba                	add	a3,a3,a4
    80006312:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006316:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000631a:	6798                	ld	a4,8(a5)
    8000631c:	00275783          	lhu	a5,2(a4)
    80006320:	2785                	addiw	a5,a5,1
    80006322:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006326:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000632a:	100017b7          	lui	a5,0x10001
    8000632e:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006332:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006336:	0001c917          	auipc	s2,0x1c
    8000633a:	35290913          	addi	s2,s2,850 # 80022688 <disk+0x128>
  while(b->disk == 1) {
    8000633e:	4485                	li	s1,1
    80006340:	00b79c63          	bne	a5,a1,80006358 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006344:	85ca                	mv	a1,s2
    80006346:	8552                	mv	a0,s4
    80006348:	ffffc097          	auipc	ra,0xffffc
    8000634c:	db2080e7          	jalr	-590(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006350:	004a2783          	lw	a5,4(s4)
    80006354:	fe9788e3          	beq	a5,s1,80006344 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006358:	f9042903          	lw	s2,-112(s0)
    8000635c:	00290713          	addi	a4,s2,2
    80006360:	0712                	slli	a4,a4,0x4
    80006362:	0001c797          	auipc	a5,0x1c
    80006366:	1fe78793          	addi	a5,a5,510 # 80022560 <disk>
    8000636a:	97ba                	add	a5,a5,a4
    8000636c:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006370:	0001c997          	auipc	s3,0x1c
    80006374:	1f098993          	addi	s3,s3,496 # 80022560 <disk>
    80006378:	00491713          	slli	a4,s2,0x4
    8000637c:	0009b783          	ld	a5,0(s3)
    80006380:	97ba                	add	a5,a5,a4
    80006382:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006386:	854a                	mv	a0,s2
    80006388:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000638c:	00000097          	auipc	ra,0x0
    80006390:	9ea080e7          	jalr	-1558(ra) # 80005d76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006394:	8885                	andi	s1,s1,1
    80006396:	f0ed                	bnez	s1,80006378 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006398:	0001c517          	auipc	a0,0x1c
    8000639c:	2f050513          	addi	a0,a0,752 # 80022688 <disk+0x128>
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	95c080e7          	jalr	-1700(ra) # 80000cfc <release>
}
    800063a8:	70a6                	ld	ra,104(sp)
    800063aa:	7406                	ld	s0,96(sp)
    800063ac:	64e6                	ld	s1,88(sp)
    800063ae:	6946                	ld	s2,80(sp)
    800063b0:	69a6                	ld	s3,72(sp)
    800063b2:	6a06                	ld	s4,64(sp)
    800063b4:	7ae2                	ld	s5,56(sp)
    800063b6:	7b42                	ld	s6,48(sp)
    800063b8:	7ba2                	ld	s7,40(sp)
    800063ba:	7c02                	ld	s8,32(sp)
    800063bc:	6ce2                	ld	s9,24(sp)
    800063be:	6d42                	ld	s10,16(sp)
    800063c0:	6165                	addi	sp,sp,112
    800063c2:	8082                	ret

00000000800063c4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063c4:	1101                	addi	sp,sp,-32
    800063c6:	ec06                	sd	ra,24(sp)
    800063c8:	e822                	sd	s0,16(sp)
    800063ca:	e426                	sd	s1,8(sp)
    800063cc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063ce:	0001c497          	auipc	s1,0x1c
    800063d2:	19248493          	addi	s1,s1,402 # 80022560 <disk>
    800063d6:	0001c517          	auipc	a0,0x1c
    800063da:	2b250513          	addi	a0,a0,690 # 80022688 <disk+0x128>
    800063de:	ffffb097          	auipc	ra,0xffffb
    800063e2:	86a080e7          	jalr	-1942(ra) # 80000c48 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063e6:	10001737          	lui	a4,0x10001
    800063ea:	533c                	lw	a5,96(a4)
    800063ec:	8b8d                	andi	a5,a5,3
    800063ee:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063f0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063f4:	689c                	ld	a5,16(s1)
    800063f6:	0204d703          	lhu	a4,32(s1)
    800063fa:	0027d783          	lhu	a5,2(a5)
    800063fe:	04f70863          	beq	a4,a5,8000644e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006402:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006406:	6898                	ld	a4,16(s1)
    80006408:	0204d783          	lhu	a5,32(s1)
    8000640c:	8b9d                	andi	a5,a5,7
    8000640e:	078e                	slli	a5,a5,0x3
    80006410:	97ba                	add	a5,a5,a4
    80006412:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006414:	00278713          	addi	a4,a5,2
    80006418:	0712                	slli	a4,a4,0x4
    8000641a:	9726                	add	a4,a4,s1
    8000641c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006420:	e721                	bnez	a4,80006468 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006422:	0789                	addi	a5,a5,2
    80006424:	0792                	slli	a5,a5,0x4
    80006426:	97a6                	add	a5,a5,s1
    80006428:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000642a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000642e:	ffffc097          	auipc	ra,0xffffc
    80006432:	d30080e7          	jalr	-720(ra) # 8000215e <wakeup>

    disk.used_idx += 1;
    80006436:	0204d783          	lhu	a5,32(s1)
    8000643a:	2785                	addiw	a5,a5,1
    8000643c:	17c2                	slli	a5,a5,0x30
    8000643e:	93c1                	srli	a5,a5,0x30
    80006440:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006444:	6898                	ld	a4,16(s1)
    80006446:	00275703          	lhu	a4,2(a4)
    8000644a:	faf71ce3          	bne	a4,a5,80006402 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000644e:	0001c517          	auipc	a0,0x1c
    80006452:	23a50513          	addi	a0,a0,570 # 80022688 <disk+0x128>
    80006456:	ffffb097          	auipc	ra,0xffffb
    8000645a:	8a6080e7          	jalr	-1882(ra) # 80000cfc <release>
}
    8000645e:	60e2                	ld	ra,24(sp)
    80006460:	6442                	ld	s0,16(sp)
    80006462:	64a2                	ld	s1,8(sp)
    80006464:	6105                	addi	sp,sp,32
    80006466:	8082                	ret
      panic("virtio_disk_intr status");
    80006468:	00002517          	auipc	a0,0x2
    8000646c:	44050513          	addi	a0,a0,1088 # 800088a8 <syscalls+0x450>
    80006470:	ffffa097          	auipc	ra,0xffffa
    80006474:	0d0080e7          	jalr	208(ra) # 80000540 <panic>

0000000080006478 <ramdiskinit>:
/* TODO: find the location of the QEMU ramdisk. */
#define RAMDISK 0x84000000

void
ramdiskinit(void)
{
    80006478:	1141                	addi	sp,sp,-16
    8000647a:	e422                	sd	s0,8(sp)
    8000647c:	0800                	addi	s0,sp,16
}
    8000647e:	6422                	ld	s0,8(sp)
    80006480:	0141                	addi	sp,sp,16
    80006482:	8082                	ret

0000000080006484 <ramdiskrw>:

// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
ramdiskrw(struct buf *b)
{
    80006484:	1101                	addi	sp,sp,-32
    80006486:	ec06                	sd	ra,24(sp)
    80006488:	e822                	sd	s0,16(sp)
    8000648a:	e426                	sd	s1,8(sp)
    8000648c:	1000                	addi	s0,sp,32
    panic("ramdiskrw: buf not locked");
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
    panic("ramdiskrw: nothing to do");
#endif

  if(b->blockno >= FSSIZE)
    8000648e:	454c                	lw	a1,12(a0)
    80006490:	7cf00793          	li	a5,1999
    80006494:	02b7ea63          	bltu	a5,a1,800064c8 <ramdiskrw+0x44>
    80006498:	84aa                	mv	s1,a0
    panic("ramdiskrw: blockno too big");

  uint64 diskaddr = b->blockno * BSIZE;
    8000649a:	00a5959b          	slliw	a1,a1,0xa
    8000649e:	1582                	slli	a1,a1,0x20
    800064a0:	9181                	srli	a1,a1,0x20
  char *addr = (char *)RAMDISK + diskaddr;

  // read from the location
  memmove(b->data, addr, BSIZE);
    800064a2:	40000613          	li	a2,1024
    800064a6:	02100793          	li	a5,33
    800064aa:	07ea                	slli	a5,a5,0x1a
    800064ac:	95be                	add	a1,a1,a5
    800064ae:	05850513          	addi	a0,a0,88
    800064b2:	ffffb097          	auipc	ra,0xffffb
    800064b6:	8ee080e7          	jalr	-1810(ra) # 80000da0 <memmove>
  b->valid = 1;
    800064ba:	4785                	li	a5,1
    800064bc:	c09c                	sw	a5,0(s1)
    // read
    memmove(b->data, addr, BSIZE);
    b->flags |= B_VALID;
  }
#endif
}
    800064be:	60e2                	ld	ra,24(sp)
    800064c0:	6442                	ld	s0,16(sp)
    800064c2:	64a2                	ld	s1,8(sp)
    800064c4:	6105                	addi	sp,sp,32
    800064c6:	8082                	ret
    panic("ramdiskrw: blockno too big");
    800064c8:	00002517          	auipc	a0,0x2
    800064cc:	3f850513          	addi	a0,a0,1016 # 800088c0 <syscalls+0x468>
    800064d0:	ffffa097          	auipc	ra,0xffffa
    800064d4:	070080e7          	jalr	112(ra) # 80000540 <panic>

00000000800064d8 <dump_hex>:
#include "fs.h"
#include "buf.h"
#include <stddef.h>

/* Acknowledgement: https://gist.github.com/ccbrown/9722406 */
void dump_hex(const void* data, size_t size) {
    800064d8:	7119                	addi	sp,sp,-128
    800064da:	fc86                	sd	ra,120(sp)
    800064dc:	f8a2                	sd	s0,112(sp)
    800064de:	f4a6                	sd	s1,104(sp)
    800064e0:	f0ca                	sd	s2,96(sp)
    800064e2:	ecce                	sd	s3,88(sp)
    800064e4:	e8d2                	sd	s4,80(sp)
    800064e6:	e4d6                	sd	s5,72(sp)
    800064e8:	e0da                	sd	s6,64(sp)
    800064ea:	fc5e                	sd	s7,56(sp)
    800064ec:	f862                	sd	s8,48(sp)
    800064ee:	f466                	sd	s9,40(sp)
    800064f0:	0100                	addi	s0,sp,128
	char ascii[17];
	size_t i, j;
	ascii[16] = '\0';
    800064f2:	f8040c23          	sb	zero,-104(s0)
	for (i = 0; i < size; ++i) {
    800064f6:	c5e1                	beqz	a1,800065be <dump_hex+0xe6>
    800064f8:	89ae                	mv	s3,a1
    800064fa:	892a                	mv	s2,a0
    800064fc:	4481                	li	s1,0
		printf("%x ", ((unsigned char*)data)[i]);
    800064fe:	00002a97          	auipc	s5,0x2
    80006502:	3e2a8a93          	addi	s5,s5,994 # 800088e0 <syscalls+0x488>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    80006506:	05e00a13          	li	s4,94
			ascii[i % 16] = ((unsigned char*)data)[i];
		} else {
			ascii[i % 16] = '.';
    8000650a:	02e00b13          	li	s6,46
		}
		if ((i+1) % 8 == 0 || i+1 == size) {
			printf(" ");
			if ((i+1) % 16 == 0) {
				printf("|  %s \n", ascii);
    8000650e:	00002c17          	auipc	s8,0x2
    80006512:	3e2c0c13          	addi	s8,s8,994 # 800088f0 <syscalls+0x498>
			printf(" ");
    80006516:	00002b97          	auipc	s7,0x2
    8000651a:	3d2b8b93          	addi	s7,s7,978 # 800088e8 <syscalls+0x490>
    8000651e:	a839                	j	8000653c <dump_hex+0x64>
			ascii[i % 16] = '.';
    80006520:	00f4f793          	andi	a5,s1,15
    80006524:	fa078793          	addi	a5,a5,-96
    80006528:	97a2                	add	a5,a5,s0
    8000652a:	ff678423          	sb	s6,-24(a5)
		if ((i+1) % 8 == 0 || i+1 == size) {
    8000652e:	0485                	addi	s1,s1,1
    80006530:	0074f793          	andi	a5,s1,7
    80006534:	cb9d                	beqz	a5,8000656a <dump_hex+0x92>
    80006536:	0b348a63          	beq	s1,s3,800065ea <dump_hex+0x112>
	for (i = 0; i < size; ++i) {
    8000653a:	0905                	addi	s2,s2,1
		printf("%x ", ((unsigned char*)data)[i]);
    8000653c:	00094583          	lbu	a1,0(s2)
    80006540:	8556                	mv	a0,s5
    80006542:	ffffa097          	auipc	ra,0xffffa
    80006546:	048080e7          	jalr	72(ra) # 8000058a <printf>
		if (((unsigned char*)data)[i] >= ' ' && ((unsigned char*)data)[i] <= '~') {
    8000654a:	00094703          	lbu	a4,0(s2)
    8000654e:	fe07079b          	addiw	a5,a4,-32
    80006552:	0ff7f793          	zext.b	a5,a5
    80006556:	fcfa65e3          	bltu	s4,a5,80006520 <dump_hex+0x48>
			ascii[i % 16] = ((unsigned char*)data)[i];
    8000655a:	00f4f793          	andi	a5,s1,15
    8000655e:	fa078793          	addi	a5,a5,-96
    80006562:	97a2                	add	a5,a5,s0
    80006564:	fee78423          	sb	a4,-24(a5)
    80006568:	b7d9                	j	8000652e <dump_hex+0x56>
			printf(" ");
    8000656a:	855e                	mv	a0,s7
    8000656c:	ffffa097          	auipc	ra,0xffffa
    80006570:	01e080e7          	jalr	30(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    80006574:	00f4fc93          	andi	s9,s1,15
    80006578:	080c8263          	beqz	s9,800065fc <dump_hex+0x124>
			} else if (i+1 == size) {
    8000657c:	fb349fe3          	bne	s1,s3,8000653a <dump_hex+0x62>
				ascii[(i+1) % 16] = '\0';
    80006580:	fa0c8793          	addi	a5,s9,-96
    80006584:	97a2                	add	a5,a5,s0
    80006586:	fe078423          	sb	zero,-24(a5)
				if ((i+1) % 16 <= 8) {
    8000658a:	47a1                	li	a5,8
    8000658c:	0597f663          	bgeu	a5,s9,800065d8 <dump_hex+0x100>
					printf(" ");
				}
				for (j = (i+1) % 16; j < 16; ++j) {
					printf("   ");
    80006590:	00002917          	auipc	s2,0x2
    80006594:	36890913          	addi	s2,s2,872 # 800088f8 <syscalls+0x4a0>
				for (j = (i+1) % 16; j < 16; ++j) {
    80006598:	44bd                	li	s1,15
					printf("   ");
    8000659a:	854a                	mv	a0,s2
    8000659c:	ffffa097          	auipc	ra,0xffffa
    800065a0:	fee080e7          	jalr	-18(ra) # 8000058a <printf>
				for (j = (i+1) % 16; j < 16; ++j) {
    800065a4:	0c85                	addi	s9,s9,1
    800065a6:	ff94fae3          	bgeu	s1,s9,8000659a <dump_hex+0xc2>
				}
				printf("|  %s \n", ascii);
    800065aa:	f8840593          	addi	a1,s0,-120
    800065ae:	00002517          	auipc	a0,0x2
    800065b2:	34250513          	addi	a0,a0,834 # 800088f0 <syscalls+0x498>
    800065b6:	ffffa097          	auipc	ra,0xffffa
    800065ba:	fd4080e7          	jalr	-44(ra) # 8000058a <printf>
			}
		}
	}
    800065be:	70e6                	ld	ra,120(sp)
    800065c0:	7446                	ld	s0,112(sp)
    800065c2:	74a6                	ld	s1,104(sp)
    800065c4:	7906                	ld	s2,96(sp)
    800065c6:	69e6                	ld	s3,88(sp)
    800065c8:	6a46                	ld	s4,80(sp)
    800065ca:	6aa6                	ld	s5,72(sp)
    800065cc:	6b06                	ld	s6,64(sp)
    800065ce:	7be2                	ld	s7,56(sp)
    800065d0:	7c42                	ld	s8,48(sp)
    800065d2:	7ca2                	ld	s9,40(sp)
    800065d4:	6109                	addi	sp,sp,128
    800065d6:	8082                	ret
					printf(" ");
    800065d8:	00002517          	auipc	a0,0x2
    800065dc:	31050513          	addi	a0,a0,784 # 800088e8 <syscalls+0x490>
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	faa080e7          	jalr	-86(ra) # 8000058a <printf>
    800065e8:	b765                	j	80006590 <dump_hex+0xb8>
			printf(" ");
    800065ea:	855e                	mv	a0,s7
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	f9e080e7          	jalr	-98(ra) # 8000058a <printf>
			if ((i+1) % 16 == 0) {
    800065f4:	00f9fc93          	andi	s9,s3,15
    800065f8:	f80c94e3          	bnez	s9,80006580 <dump_hex+0xa8>
				printf("|  %s \n", ascii);
    800065fc:	f8840593          	addi	a1,s0,-120
    80006600:	8562                	mv	a0,s8
    80006602:	ffffa097          	auipc	ra,0xffffa
    80006606:	f88080e7          	jalr	-120(ra) # 8000058a <printf>
	for (i = 0; i < size; ++i) {
    8000660a:	fb348ae3          	beq	s1,s3,800065be <dump_hex+0xe6>
    8000660e:	0905                	addi	s2,s2,1
    80006610:	b735                	j	8000653c <dump_hex+0x64>

0000000080006612 <find_reg>:
    uint64 curr_mode;
};

struct vm_virtual_state vm_state;

struct vm_reg find_reg(unsigned int uimm) {
    80006612:	1101                	addi	sp,sp,-32
    80006614:	ec22                	sd	s0,24(sp)
    80006616:	1000                	addi	s0,sp,32
    static struct vm_virtual_state v;

    if(uimm == 0x000)
    80006618:	34b00793          	li	a5,843
    8000661c:	0ca7ec63          	bltu	a5,a0,800066f4 <find_reg+0xe2>
    80006620:	2ff00793          	li	a5,767
    80006624:	08a7e363          	bltu	a5,a0,800066aa <find_reg+0x98>
    80006628:	14400793          	li	a5,324
    8000662c:	0aa7e363          	bltu	a5,a0,800066d2 <find_reg+0xc0>
    80006630:	0ff00793          	li	a5,255
    80006634:	02a7f663          	bgeu	a5,a0,80006660 <find_reg+0x4e>
    80006638:	f005051b          	addiw	a0,a0,-256
    8000663c:	0005071b          	sext.w	a4,a0
    80006640:	04400793          	li	a5,68
    80006644:	42e7e463          	bltu	a5,a4,80006a6c <find_reg+0x45a>
    80006648:	02051793          	slli	a5,a0,0x20
    8000664c:	01e7d513          	srli	a0,a5,0x1e
    80006650:	00002717          	auipc	a4,0x2
    80006654:	2b070713          	addi	a4,a4,688 # 80008900 <syscalls+0x4a8>
    80006658:	953a                	add	a0,a0,a4
    8000665a:	411c                	lw	a5,0(a0)
    8000665c:	97ba                	add	a5,a5,a4
    8000665e:	8782                	jr	a5
    80006660:	4791                	li	a5,4
    80006662:	12f50163          	beq	a0,a5,80006784 <find_reg+0x172>
    80006666:	04000793          	li	a5,64
    8000666a:	00f51d63          	bne	a0,a5,80006684 <find_reg+0x72>
        return v.ustatus;
    else if (uimm == 0x004)
        return v.uie;
    else if (uimm == 0x040)
        return v.uscratch;
    8000666e:	00002797          	auipc	a5,0x2
    80006672:	4da78793          	addi	a5,a5,1242 # 80008b48 <v.0>
    80006676:	63b8                	ld	a4,64(a5)
    80006678:	fee43023          	sd	a4,-32(s0)
    8000667c:	67bc                	ld	a5,72(a5)
    8000667e:	fef43423          	sd	a5,-24(s0)
    80006682:	a829                	j	8000669c <find_reg+0x8a>
    80006684:	3e051463          	bnez	a0,80006a6c <find_reg+0x45a>
        return v.ustatus;
    80006688:	00002797          	auipc	a5,0x2
    8000668c:	4c078793          	addi	a5,a5,1216 # 80008b48 <v.0>
    80006690:	6398                	ld	a4,0(a5)
    80006692:	fee43023          	sd	a4,-32(s0)
    80006696:	679c                	ld	a5,8(a5)
    80006698:	fef43423          	sd	a5,-24(s0)
    else {
        struct vm_reg tmp;
        tmp.val = -1;
        return tmp;
    }
};
    8000669c:	fe043503          	ld	a0,-32(s0)
    800066a0:	fe843583          	ld	a1,-24(s0)
    800066a4:	6462                	ld	s0,24(sp)
    800066a6:	6105                	addi	sp,sp,32
    800066a8:	8082                	ret
    800066aa:	d005051b          	addiw	a0,a0,-768
    800066ae:	0005071b          	sext.w	a4,a0
    800066b2:	04b00793          	li	a5,75
    800066b6:	3ae7eb63          	bltu	a5,a4,80006a6c <find_reg+0x45a>
    800066ba:	02051793          	slli	a5,a0,0x20
    800066be:	01e7d513          	srli	a0,a5,0x1e
    800066c2:	00002717          	auipc	a4,0x2
    800066c6:	35270713          	addi	a4,a4,850 # 80008a14 <syscalls+0x5bc>
    800066ca:	953a                	add	a0,a0,a4
    800066cc:	411c                	lw	a5,0(a0)
    800066ce:	97ba                	add	a5,a5,a4
    800066d0:	8782                	jr	a5
    800066d2:	18000793          	li	a5,384
    800066d6:	38f51b63          	bne	a0,a5,80006a6c <find_reg+0x45a>
        return v.satp;
    800066da:	00002797          	auipc	a5,0x2
    800066de:	46e78793          	addi	a5,a5,1134 # 80008b48 <v.0>
    800066e2:	1307b703          	ld	a4,304(a5)
    800066e6:	fee43023          	sd	a4,-32(s0)
    800066ea:	1387b783          	ld	a5,312(a5)
    800066ee:	fef43423          	sd	a5,-24(s0)
    800066f2:	b76d                	j	8000669c <find_reg+0x8a>
    800066f4:	6785                	lui	a5,0x1
    800066f6:	f1278793          	addi	a5,a5,-238 # f12 <_entry-0x7ffff0ee>
    800066fa:	18f50f63          	beq	a0,a5,80006898 <find_reg+0x286>
    800066fe:	6785                	lui	a5,0x1
    80006700:	f1278793          	addi	a5,a5,-238 # f12 <_entry-0x7ffff0ee>
    80006704:	02a7f963          	bgeu	a5,a0,80006736 <find_reg+0x124>
    80006708:	6785                	lui	a5,0x1
    8000670a:	f1378793          	addi	a5,a5,-237 # f13 <_entry-0x7ffff0ed>
    8000670e:	1af50263          	beq	a0,a5,800068b2 <find_reg+0x2a0>
    80006712:	6785                	lui	a5,0x1
    80006714:	f1478793          	addi	a5,a5,-236 # f14 <_entry-0x7ffff0ec>
    80006718:	34f51a63          	bne	a0,a5,80006a6c <find_reg+0x45a>
        return v.mhartid;
    8000671c:	00002797          	auipc	a5,0x2
    80006720:	42c78793          	addi	a5,a5,1068 # 80008b48 <v.0>
    80006724:	1707b703          	ld	a4,368(a5)
    80006728:	fee43023          	sd	a4,-32(s0)
    8000672c:	1787b783          	ld	a5,376(a5)
    80006730:	fef43423          	sd	a5,-24(s0)
    80006734:	b7a5                	j	8000669c <find_reg+0x8a>
    80006736:	3b000793          	li	a5,944
    8000673a:	30f50c63          	beq	a0,a5,80006a52 <find_reg+0x440>
    8000673e:	6785                	lui	a5,0x1
    80006740:	f1178793          	addi	a5,a5,-239 # f11 <_entry-0x7ffff0ef>
    80006744:	00f51f63          	bne	a0,a5,80006762 <find_reg+0x150>
        return v.mvendorid;
    80006748:	00002797          	auipc	a5,0x2
    8000674c:	40078793          	addi	a5,a5,1024 # 80008b48 <v.0>
    80006750:	1407b703          	ld	a4,320(a5)
    80006754:	fee43023          	sd	a4,-32(s0)
    80006758:	1487b783          	ld	a5,328(a5)
    8000675c:	fef43423          	sd	a5,-24(s0)
    80006760:	bf35                	j	8000669c <find_reg+0x8a>
    80006762:	3a000793          	li	a5,928
    80006766:	30f51363          	bne	a0,a5,80006a6c <find_reg+0x45a>
        return v.pmpcgf;
    8000676a:	00002797          	auipc	a5,0x2
    8000676e:	3de78793          	addi	a5,a5,990 # 80008b48 <v.0>
    80006772:	2787b703          	ld	a4,632(a5)
    80006776:	fee43023          	sd	a4,-32(s0)
    8000677a:	2807b783          	ld	a5,640(a5)
    8000677e:	fef43423          	sd	a5,-24(s0)
    80006782:	bf29                	j	8000669c <find_reg+0x8a>
        return v.uie;
    80006784:	00002797          	auipc	a5,0x2
    80006788:	3c478793          	addi	a5,a5,964 # 80008b48 <v.0>
    8000678c:	7398                	ld	a4,32(a5)
    8000678e:	fee43023          	sd	a4,-32(s0)
    80006792:	779c                	ld	a5,40(a5)
    80006794:	fef43423          	sd	a5,-24(s0)
    80006798:	b711                	j	8000669c <find_reg+0x8a>
        return v.sstatus;
    8000679a:	00002797          	auipc	a5,0x2
    8000679e:	3ae78793          	addi	a5,a5,942 # 80008b48 <v.0>
    800067a2:	63d8                	ld	a4,128(a5)
    800067a4:	fee43023          	sd	a4,-32(s0)
    800067a8:	67dc                	ld	a5,136(a5)
    800067aa:	fef43423          	sd	a5,-24(s0)
    800067ae:	b5fd                	j	8000669c <find_reg+0x8a>
        return v.sedeleg;
    800067b0:	00002797          	auipc	a5,0x2
    800067b4:	39878793          	addi	a5,a5,920 # 80008b48 <v.0>
    800067b8:	6bd8                	ld	a4,144(a5)
    800067ba:	fee43023          	sd	a4,-32(s0)
    800067be:	6fdc                	ld	a5,152(a5)
    800067c0:	fef43423          	sd	a5,-24(s0)
    800067c4:	bde1                	j	8000669c <find_reg+0x8a>
        return v.sideleg;
    800067c6:	00002797          	auipc	a5,0x2
    800067ca:	38278793          	addi	a5,a5,898 # 80008b48 <v.0>
    800067ce:	73d8                	ld	a4,160(a5)
    800067d0:	fee43023          	sd	a4,-32(s0)
    800067d4:	77dc                	ld	a5,168(a5)
    800067d6:	fef43423          	sd	a5,-24(s0)
    800067da:	b5c9                	j	8000669c <find_reg+0x8a>
        return v.sie;
    800067dc:	00002797          	auipc	a5,0x2
    800067e0:	36c78793          	addi	a5,a5,876 # 80008b48 <v.0>
    800067e4:	63f8                	ld	a4,192(a5)
    800067e6:	fee43023          	sd	a4,-32(s0)
    800067ea:	67fc                	ld	a5,200(a5)
    800067ec:	fef43423          	sd	a5,-24(s0)
    800067f0:	b575                	j	8000669c <find_reg+0x8a>
        return v.stvec;
    800067f2:	00002797          	auipc	a5,0x2
    800067f6:	35678793          	addi	a5,a5,854 # 80008b48 <v.0>
    800067fa:	7bd8                	ld	a4,176(a5)
    800067fc:	fee43023          	sd	a4,-32(s0)
    80006800:	7fdc                	ld	a5,184(a5)
    80006802:	fef43423          	sd	a5,-24(s0)
    80006806:	bd59                	j	8000669c <find_reg+0x8a>
        return v.scounteren;
    80006808:	00002797          	auipc	a5,0x2
    8000680c:	34078793          	addi	a5,a5,832 # 80008b48 <v.0>
    80006810:	6bf8                	ld	a4,208(a5)
    80006812:	fee43023          	sd	a4,-32(s0)
    80006816:	6ffc                	ld	a5,216(a5)
    80006818:	fef43423          	sd	a5,-24(s0)
    8000681c:	b541                	j	8000669c <find_reg+0x8a>
        return v.sscratch;
    8000681e:	00002797          	auipc	a5,0x2
    80006822:	32a78793          	addi	a5,a5,810 # 80008b48 <v.0>
    80006826:	73f8                	ld	a4,224(a5)
    80006828:	fee43023          	sd	a4,-32(s0)
    8000682c:	77fc                	ld	a5,232(a5)
    8000682e:	fef43423          	sd	a5,-24(s0)
    80006832:	b5ad                	j	8000669c <find_reg+0x8a>
        return v.sepc;
    80006834:	00002797          	auipc	a5,0x2
    80006838:	31478793          	addi	a5,a5,788 # 80008b48 <v.0>
    8000683c:	7bf8                	ld	a4,240(a5)
    8000683e:	fee43023          	sd	a4,-32(s0)
    80006842:	7ffc                	ld	a5,248(a5)
    80006844:	fef43423          	sd	a5,-24(s0)
    80006848:	bd91                	j	8000669c <find_reg+0x8a>
        return v.scause;
    8000684a:	00002797          	auipc	a5,0x2
    8000684e:	2fe78793          	addi	a5,a5,766 # 80008b48 <v.0>
    80006852:	1007b703          	ld	a4,256(a5)
    80006856:	fee43023          	sd	a4,-32(s0)
    8000685a:	1087b783          	ld	a5,264(a5)
    8000685e:	fef43423          	sd	a5,-24(s0)
    80006862:	bd2d                	j	8000669c <find_reg+0x8a>
        return v.stval;
    80006864:	00002797          	auipc	a5,0x2
    80006868:	2e478793          	addi	a5,a5,740 # 80008b48 <v.0>
    8000686c:	1107b703          	ld	a4,272(a5)
    80006870:	fee43023          	sd	a4,-32(s0)
    80006874:	1187b783          	ld	a5,280(a5)
    80006878:	fef43423          	sd	a5,-24(s0)
    8000687c:	b505                	j	8000669c <find_reg+0x8a>
        return v.sip;
    8000687e:	00002797          	auipc	a5,0x2
    80006882:	2ca78793          	addi	a5,a5,714 # 80008b48 <v.0>
    80006886:	1207b703          	ld	a4,288(a5)
    8000688a:	fee43023          	sd	a4,-32(s0)
    8000688e:	1287b783          	ld	a5,296(a5)
    80006892:	fef43423          	sd	a5,-24(s0)
    80006896:	b519                	j	8000669c <find_reg+0x8a>
        return v.marchid;
    80006898:	00002797          	auipc	a5,0x2
    8000689c:	2b078793          	addi	a5,a5,688 # 80008b48 <v.0>
    800068a0:	1507b703          	ld	a4,336(a5)
    800068a4:	fee43023          	sd	a4,-32(s0)
    800068a8:	1587b783          	ld	a5,344(a5)
    800068ac:	fef43423          	sd	a5,-24(s0)
    800068b0:	b3f5                	j	8000669c <find_reg+0x8a>
        return v.mimpid;
    800068b2:	00002797          	auipc	a5,0x2
    800068b6:	29678793          	addi	a5,a5,662 # 80008b48 <v.0>
    800068ba:	1607b703          	ld	a4,352(a5)
    800068be:	fee43023          	sd	a4,-32(s0)
    800068c2:	1687b783          	ld	a5,360(a5)
    800068c6:	fef43423          	sd	a5,-24(s0)
    800068ca:	bbc9                	j	8000669c <find_reg+0x8a>
        return v.mstatus;
    800068cc:	00002797          	auipc	a5,0x2
    800068d0:	27c78793          	addi	a5,a5,636 # 80008b48 <v.0>
    800068d4:	1907b703          	ld	a4,400(a5)
    800068d8:	fee43023          	sd	a4,-32(s0)
    800068dc:	1987b783          	ld	a5,408(a5)
    800068e0:	fef43423          	sd	a5,-24(s0)
    800068e4:	bb65                	j	8000669c <find_reg+0x8a>
        return v.misa;
    800068e6:	00002797          	auipc	a5,0x2
    800068ea:	26278793          	addi	a5,a5,610 # 80008b48 <v.0>
    800068ee:	1807b703          	ld	a4,384(a5)
    800068f2:	fee43023          	sd	a4,-32(s0)
    800068f6:	1887b783          	ld	a5,392(a5)
    800068fa:	fef43423          	sd	a5,-24(s0)
    800068fe:	bb79                	j	8000669c <find_reg+0x8a>
        return v.medeleg;
    80006900:	00002797          	auipc	a5,0x2
    80006904:	24878793          	addi	a5,a5,584 # 80008b48 <v.0>
    80006908:	1b07b703          	ld	a4,432(a5)
    8000690c:	fee43023          	sd	a4,-32(s0)
    80006910:	1b87b783          	ld	a5,440(a5)
    80006914:	fef43423          	sd	a5,-24(s0)
    80006918:	b351                	j	8000669c <find_reg+0x8a>
        return v.mideleg;
    8000691a:	00002797          	auipc	a5,0x2
    8000691e:	22e78793          	addi	a5,a5,558 # 80008b48 <v.0>
    80006922:	1c07b703          	ld	a4,448(a5)
    80006926:	fee43023          	sd	a4,-32(s0)
    8000692a:	1c87b783          	ld	a5,456(a5)
    8000692e:	fef43423          	sd	a5,-24(s0)
    80006932:	b3ad                	j	8000669c <find_reg+0x8a>
        return v.mie;
    80006934:	00002797          	auipc	a5,0x2
    80006938:	21478793          	addi	a5,a5,532 # 80008b48 <v.0>
    8000693c:	1d07b703          	ld	a4,464(a5)
    80006940:	fee43023          	sd	a4,-32(s0)
    80006944:	1d87b783          	ld	a5,472(a5)
    80006948:	fef43423          	sd	a5,-24(s0)
    8000694c:	bb81                	j	8000669c <find_reg+0x8a>
        return v.mtvec;
    8000694e:	00002797          	auipc	a5,0x2
    80006952:	1fa78793          	addi	a5,a5,506 # 80008b48 <v.0>
    80006956:	1a07b703          	ld	a4,416(a5)
    8000695a:	fee43023          	sd	a4,-32(s0)
    8000695e:	1a87b783          	ld	a5,424(a5)
    80006962:	fef43423          	sd	a5,-24(s0)
    80006966:	bb1d                	j	8000669c <find_reg+0x8a>
        return v.mcounteren;
    80006968:	00002797          	auipc	a5,0x2
    8000696c:	1e078793          	addi	a5,a5,480 # 80008b48 <v.0>
    80006970:	1e07b703          	ld	a4,480(a5)
    80006974:	fee43023          	sd	a4,-32(s0)
    80006978:	1e87b783          	ld	a5,488(a5)
    8000697c:	fef43423          	sd	a5,-24(s0)
    80006980:	bb31                	j	8000669c <find_reg+0x8a>
        return v.mstatush;
    80006982:	00002797          	auipc	a5,0x2
    80006986:	1c678793          	addi	a5,a5,454 # 80008b48 <v.0>
    8000698a:	1f07b703          	ld	a4,496(a5)
    8000698e:	fee43023          	sd	a4,-32(s0)
    80006992:	1f87b783          	ld	a5,504(a5)
    80006996:	fef43423          	sd	a5,-24(s0)
    8000699a:	b309                	j	8000669c <find_reg+0x8a>
        return v.mscratch;
    8000699c:	00002797          	auipc	a5,0x2
    800069a0:	1ac78793          	addi	a5,a5,428 # 80008b48 <v.0>
    800069a4:	2007b703          	ld	a4,512(a5)
    800069a8:	fee43023          	sd	a4,-32(s0)
    800069ac:	2087b783          	ld	a5,520(a5)
    800069b0:	fef43423          	sd	a5,-24(s0)
    800069b4:	b1e5                	j	8000669c <find_reg+0x8a>
        return v.mepc;
    800069b6:	00002797          	auipc	a5,0x2
    800069ba:	19278793          	addi	a5,a5,402 # 80008b48 <v.0>
    800069be:	2107b703          	ld	a4,528(a5)
    800069c2:	fee43023          	sd	a4,-32(s0)
    800069c6:	2187b783          	ld	a5,536(a5)
    800069ca:	fef43423          	sd	a5,-24(s0)
    800069ce:	b1f9                	j	8000669c <find_reg+0x8a>
        return v.mcause;
    800069d0:	00002797          	auipc	a5,0x2
    800069d4:	17878793          	addi	a5,a5,376 # 80008b48 <v.0>
    800069d8:	2307b703          	ld	a4,560(a5)
    800069dc:	fee43023          	sd	a4,-32(s0)
    800069e0:	2387b783          	ld	a5,568(a5)
    800069e4:	fef43423          	sd	a5,-24(s0)
    800069e8:	b955                	j	8000669c <find_reg+0x8a>
        return v.mtval;
    800069ea:	00002797          	auipc	a5,0x2
    800069ee:	15e78793          	addi	a5,a5,350 # 80008b48 <v.0>
    800069f2:	2207b703          	ld	a4,544(a5)
    800069f6:	fee43023          	sd	a4,-32(s0)
    800069fa:	2287b783          	ld	a5,552(a5)
    800069fe:	fef43423          	sd	a5,-24(s0)
    80006a02:	b969                	j	8000669c <find_reg+0x8a>
        return v.mip;
    80006a04:	00002797          	auipc	a5,0x2
    80006a08:	14478793          	addi	a5,a5,324 # 80008b48 <v.0>
    80006a0c:	2407b703          	ld	a4,576(a5)
    80006a10:	fee43023          	sd	a4,-32(s0)
    80006a14:	2487b783          	ld	a5,584(a5)
    80006a18:	fef43423          	sd	a5,-24(s0)
    80006a1c:	b141                	j	8000669c <find_reg+0x8a>
        return v.mtinst;
    80006a1e:	00002797          	auipc	a5,0x2
    80006a22:	12a78793          	addi	a5,a5,298 # 80008b48 <v.0>
    80006a26:	2507b703          	ld	a4,592(a5)
    80006a2a:	fee43023          	sd	a4,-32(s0)
    80006a2e:	2587b783          	ld	a5,600(a5)
    80006a32:	fef43423          	sd	a5,-24(s0)
    80006a36:	b19d                	j	8000669c <find_reg+0x8a>
        return v.mtval2;
    80006a38:	00002797          	auipc	a5,0x2
    80006a3c:	11078793          	addi	a5,a5,272 # 80008b48 <v.0>
    80006a40:	2607b703          	ld	a4,608(a5)
    80006a44:	fee43023          	sd	a4,-32(s0)
    80006a48:	2687b783          	ld	a5,616(a5)
    80006a4c:	fef43423          	sd	a5,-24(s0)
    80006a50:	b1b1                	j	8000669c <find_reg+0x8a>
        return v.pmpaddr;
    80006a52:	00002797          	auipc	a5,0x2
    80006a56:	0f678793          	addi	a5,a5,246 # 80008b48 <v.0>
    80006a5a:	2887b703          	ld	a4,648(a5)
    80006a5e:	fee43023          	sd	a4,-32(s0)
    80006a62:	2907b783          	ld	a5,656(a5)
    80006a66:	fef43423          	sd	a5,-24(s0)
    80006a6a:	b90d                	j	8000669c <find_reg+0x8a>
        return tmp;
    80006a6c:	fe042023          	sw	zero,-32(s0)
    80006a70:	fe042223          	sw	zero,-28(s0)
    80006a74:	57fd                	li	a5,-1
    80006a76:	fef43423          	sd	a5,-24(s0)
    80006a7a:	b10d                	j	8000669c <find_reg+0x8a>

0000000080006a7c <trap_and_emulate_init>:
    }

    kfree(pa);
}

void trap_and_emulate_init(void) {
    80006a7c:	1141                	addi	sp,sp,-16
    80006a7e:	e422                	sd	s0,8(sp)
    80006a80:	0800                	addi	s0,sp,16
    /* Create and initialize all state for the VM */
    vm_state.ustatus.code = 0x000;
    80006a82:	0001c797          	auipc	a5,0x1c
    80006a86:	c1e78793          	addi	a5,a5,-994 # 800226a0 <vm_state>
    80006a8a:	0007a023          	sw	zero,0(a5)
    vm_state.ustatus.mode = 0;
    80006a8e:	0007a223          	sw	zero,4(a5)
    vm_state.ustatus.val = 0;
    80006a92:	0007b423          	sd	zero,8(a5)

    vm_state.uie.code = 0x004;
    80006a96:	4711                	li	a4,4
    80006a98:	d398                	sw	a4,32(a5)
    vm_state.uie.mode = 0;
    80006a9a:	0207a223          	sw	zero,36(a5)
    vm_state.uie.val = 0;
    80006a9e:	0207b423          	sd	zero,40(a5)

    vm_state.uscratch.code = 0x040;
    80006aa2:	04000713          	li	a4,64
    80006aa6:	c3b8                	sw	a4,64(a5)
    vm_state.uscratch.mode = 0;
    80006aa8:	0407a223          	sw	zero,68(a5)
    vm_state.uscratch.val = 0;
    80006aac:	0407b423          	sd	zero,72(a5)

    vm_state.sstatus.code = 0x100;
    80006ab0:	10000713          	li	a4,256
    80006ab4:	08e7a023          	sw	a4,128(a5)
    vm_state.sstatus.mode = 1;
    80006ab8:	4705                	li	a4,1
    80006aba:	08e7a223          	sw	a4,132(a5)
    vm_state.sstatus.val = 0;
    80006abe:	0807b423          	sd	zero,136(a5)

    vm_state.sedeleg.code = 0x102;
    80006ac2:	10200693          	li	a3,258
    80006ac6:	08d7a823          	sw	a3,144(a5)
    vm_state.sedeleg.mode = 1;
    80006aca:	08e7aa23          	sw	a4,148(a5)
    vm_state.sedeleg.val = 0;
    80006ace:	0807bc23          	sd	zero,152(a5)

    vm_state.sideleg.code = 0x103;
    80006ad2:	10300693          	li	a3,259
    80006ad6:	0ad7a023          	sw	a3,160(a5)
    vm_state.sideleg.mode = 1;
    80006ada:	0ae7a223          	sw	a4,164(a5)
    vm_state.sideleg.val = 0;
    80006ade:	0a07b423          	sd	zero,168(a5)

    vm_state.sie.code = 0x104;
    80006ae2:	10400693          	li	a3,260
    80006ae6:	0cd7a023          	sw	a3,192(a5)
    vm_state.sie.mode = 1;
    80006aea:	0ce7a223          	sw	a4,196(a5)
    vm_state.sie.val = 0;
    80006aee:	0c07b423          	sd	zero,200(a5)

    vm_state.stvec.code = 0x105;
    80006af2:	10500693          	li	a3,261
    80006af6:	0ad7a823          	sw	a3,176(a5)
    vm_state.stvec.mode = 1;
    80006afa:	0ae7aa23          	sw	a4,180(a5)
    vm_state.stvec.val = 0;
    80006afe:	0a07bc23          	sd	zero,184(a5)

    vm_state.scounteren.code = 0x106;
    80006b02:	10600693          	li	a3,262
    80006b06:	0cd7a823          	sw	a3,208(a5)
    vm_state.scounteren.mode = 1;
    80006b0a:	0ce7aa23          	sw	a4,212(a5)
    vm_state.scounteren.val = 0;
    80006b0e:	0c07bc23          	sd	zero,216(a5)

    vm_state.sscratch.code = 0x140;
    80006b12:	14000693          	li	a3,320
    80006b16:	0ed7a023          	sw	a3,224(a5)
    vm_state.sscratch.mode = 1;
    80006b1a:	0ee7a223          	sw	a4,228(a5)
    vm_state.sscratch.val = 0;
    80006b1e:	0e07b423          	sd	zero,232(a5)

    vm_state.sepc.code = 0x141;
    80006b22:	14100693          	li	a3,321
    80006b26:	0ed7a823          	sw	a3,240(a5)
    vm_state.sepc.mode = 1;
    80006b2a:	0ee7aa23          	sw	a4,244(a5)
    vm_state.sepc.val = 0;
    80006b2e:	0e07bc23          	sd	zero,248(a5)

    vm_state.scause.code = 0x142;
    80006b32:	14200693          	li	a3,322
    80006b36:	10d7a023          	sw	a3,256(a5)
    vm_state.scause.mode = 1;
    80006b3a:	10e7a223          	sw	a4,260(a5)
    vm_state.scause.val = 0;
    80006b3e:	1007b423          	sd	zero,264(a5)

    vm_state.stval.code = 0x143;
    80006b42:	14300693          	li	a3,323
    80006b46:	10d7a823          	sw	a3,272(a5)
    vm_state.stval.mode = 1;
    80006b4a:	10e7aa23          	sw	a4,276(a5)
    vm_state.stval.val = 0;
    80006b4e:	1007bc23          	sd	zero,280(a5)

    vm_state.sip.code = 0x144;
    80006b52:	14400693          	li	a3,324
    80006b56:	12d7a023          	sw	a3,288(a5)
    vm_state.sip.mode = 1;
    80006b5a:	12e7a223          	sw	a4,292(a5)
    vm_state.sip.val = 0;
    80006b5e:	1207b423          	sd	zero,296(a5)

    vm_state.satp.code = 0x180;
    80006b62:	18000693          	li	a3,384
    80006b66:	12d7a823          	sw	a3,304(a5)
    vm_state.satp.mode = 1;
    80006b6a:	12e7aa23          	sw	a4,308(a5)
    vm_state.satp.val = 0;
    80006b6e:	1207bc23          	sd	zero,312(a5)

    vm_state.mvendorid.code = 0xf11;
    80006b72:	6685                	lui	a3,0x1
    80006b74:	f1168713          	addi	a4,a3,-239 # f11 <_entry-0x7ffff0ef>
    80006b78:	14e7a023          	sw	a4,320(a5)
    vm_state.mvendorid.mode = 2;
    80006b7c:	4709                	li	a4,2
    80006b7e:	14e7a223          	sw	a4,324(a5)
    vm_state.mvendorid.val = 0x63657365353336;
    80006b82:	00001617          	auipc	a2,0x1
    80006b86:	48663603          	ld	a2,1158(a2) # 80008008 <etext+0x8>
    80006b8a:	14c7b423          	sd	a2,328(a5)

    vm_state.marchid.code = 0xf12;
    80006b8e:	f1268613          	addi	a2,a3,-238
    80006b92:	14c7a823          	sw	a2,336(a5)
    vm_state.marchid.mode = 2;
    80006b96:	14e7aa23          	sw	a4,340(a5)
    vm_state.marchid.val = 0;
    80006b9a:	1407bc23          	sd	zero,344(a5)

    vm_state.mimpid.code = 0xf13;
    80006b9e:	f1368613          	addi	a2,a3,-237
    80006ba2:	16c7a023          	sw	a2,352(a5)
    vm_state.mimpid.mode = 2;
    80006ba6:	16e7a223          	sw	a4,356(a5)
    vm_state.mimpid.val = 0;
    80006baa:	1607b423          	sd	zero,360(a5)

    vm_state.mhartid.code = 0xf14;
    80006bae:	f1468693          	addi	a3,a3,-236
    80006bb2:	16d7a823          	sw	a3,368(a5)
    vm_state.mhartid.mode = 2;
    80006bb6:	16e7aa23          	sw	a4,372(a5)
    vm_state.mhartid.val = 0;
    80006bba:	1607bc23          	sd	zero,376(a5)

    vm_state.mstatus.code = 0x300;
    80006bbe:	30000693          	li	a3,768
    80006bc2:	18d7a823          	sw	a3,400(a5)
    vm_state.mstatus.mode = 2;
    80006bc6:	18e7aa23          	sw	a4,404(a5)
    vm_state.mstatus.val = 0;
    80006bca:	1807bc23          	sd	zero,408(a5)

    vm_state.misa.code = 0x301;
    80006bce:	30100693          	li	a3,769
    80006bd2:	18d7a023          	sw	a3,384(a5)
    vm_state.misa.mode = 2;
    80006bd6:	18e7a223          	sw	a4,388(a5)
    vm_state.misa.val = 0;
    80006bda:	1807b423          	sd	zero,392(a5)

    vm_state.medeleg.code = 0x302;
    80006bde:	30200693          	li	a3,770
    80006be2:	1ad7a823          	sw	a3,432(a5)
    vm_state.medeleg.mode = 2;
    80006be6:	1ae7aa23          	sw	a4,436(a5)
    vm_state.medeleg.val = 0;
    80006bea:	1a07bc23          	sd	zero,440(a5)

    vm_state.mideleg.code = 0x303;
    80006bee:	30300693          	li	a3,771
    80006bf2:	1cd7a023          	sw	a3,448(a5)
    vm_state.mideleg.mode = 2;
    80006bf6:	1ce7a223          	sw	a4,452(a5)
    vm_state.mideleg.val = 0;
    80006bfa:	1c07b423          	sd	zero,456(a5)

    vm_state.mie.code = 0x304;
    80006bfe:	30400693          	li	a3,772
    80006c02:	1cd7a823          	sw	a3,464(a5)
    vm_state.mie.mode = 2;
    80006c06:	1ce7aa23          	sw	a4,468(a5)
    vm_state.mie.val = 0;
    80006c0a:	1c07bc23          	sd	zero,472(a5)

    vm_state.mtvec.code = 0x305;
    80006c0e:	30500693          	li	a3,773
    80006c12:	1ad7a023          	sw	a3,416(a5)
    vm_state.mtvec.mode = 2;
    80006c16:	1ae7a223          	sw	a4,420(a5)
    vm_state.mtvec.val = 0;
    80006c1a:	1a07b423          	sd	zero,424(a5)

    vm_state.mcounteren.code = 0x306;
    80006c1e:	30600693          	li	a3,774
    80006c22:	1ed7a023          	sw	a3,480(a5)
    vm_state.mcounteren.mode = 2;
    80006c26:	1ee7a223          	sw	a4,484(a5)
    vm_state.mcounteren.val = 0;
    80006c2a:	1e07b423          	sd	zero,488(a5)

    vm_state.mstatush.code = 0x310;
    80006c2e:	31000693          	li	a3,784
    80006c32:	1ed7a823          	sw	a3,496(a5)
    vm_state.mstatush.mode = 2;
    80006c36:	1ee7aa23          	sw	a4,500(a5)
    vm_state.mstatush.val = 0;
    80006c3a:	1e07bc23          	sd	zero,504(a5)

    vm_state.mscratch.code = 0x340;
    80006c3e:	34000693          	li	a3,832
    80006c42:	20d7a023          	sw	a3,512(a5)
    vm_state.mscratch.mode = 2;
    80006c46:	20e7a223          	sw	a4,516(a5)
    vm_state.mscratch.val = 0;
    80006c4a:	2007b423          	sd	zero,520(a5)

    vm_state.mepc.code = 0x341;
    80006c4e:	34100693          	li	a3,833
    80006c52:	20d7a823          	sw	a3,528(a5)
    vm_state.mepc.mode = 2;
    80006c56:	20e7aa23          	sw	a4,532(a5)
    vm_state.mepc.val = 0;
    80006c5a:	2007bc23          	sd	zero,536(a5)

    vm_state.mcause.code = 0x342;
    80006c5e:	34200693          	li	a3,834
    80006c62:	22d7a823          	sw	a3,560(a5)
    vm_state.mcause.mode = 2;
    80006c66:	22e7aa23          	sw	a4,564(a5)
    vm_state.mcause.val = 0;
    80006c6a:	2207bc23          	sd	zero,568(a5)

    vm_state.mtval.code = 0x343;
    80006c6e:	34300693          	li	a3,835
    80006c72:	22d7a023          	sw	a3,544(a5)
    vm_state.mtval.mode = 2;
    80006c76:	22e7a223          	sw	a4,548(a5)
    vm_state.mtval.val = 0;
    80006c7a:	2207b423          	sd	zero,552(a5)

    vm_state.mip.code = 0x344;
    80006c7e:	34400693          	li	a3,836
    80006c82:	24d7a023          	sw	a3,576(a5)
    vm_state.mip.mode = 2;
    80006c86:	24e7a223          	sw	a4,580(a5)
    vm_state.mip.val = 0;
    80006c8a:	2407b423          	sd	zero,584(a5)

    vm_state.mtinst.code = 0x34a;
    80006c8e:	34a00693          	li	a3,842
    80006c92:	24d7a823          	sw	a3,592(a5)
    vm_state.mtinst.mode = 2;
    80006c96:	24e7aa23          	sw	a4,596(a5)
    vm_state.mtinst.val = 0;
    80006c9a:	2407bc23          	sd	zero,600(a5)

    vm_state.mtval2.code = 0x34b;
    80006c9e:	34b00693          	li	a3,843
    80006ca2:	26d7a023          	sw	a3,608(a5)
    vm_state.mtval2.mode = 2;
    80006ca6:	26e7a223          	sw	a4,612(a5)
    vm_state.mtval2.val = 0;
    80006caa:	2607b423          	sd	zero,616(a5)

    vm_state.curr_mode = 2;
    80006cae:	28e7bc23          	sd	a4,664(a5)
    80006cb2:	6422                	ld	s0,8(sp)
    80006cb4:	0141                	addi	sp,sp,16
    80006cb6:	8082                	ret

0000000080006cb8 <trap_and_emulate>:
void trap_and_emulate(void) {
    80006cb8:	715d                	addi	sp,sp,-80
    80006cba:	e486                	sd	ra,72(sp)
    80006cbc:	e0a2                	sd	s0,64(sp)
    80006cbe:	fc26                	sd	s1,56(sp)
    80006cc0:	f84a                	sd	s2,48(sp)
    80006cc2:	f44e                	sd	s3,40(sp)
    80006cc4:	f052                	sd	s4,32(sp)
    80006cc6:	ec56                	sd	s5,24(sp)
    80006cc8:	0880                	addi	s0,sp,80
    struct proc *p = myproc();
    80006cca:	ffffb097          	auipc	ra,0xffffb
    80006cce:	d5a080e7          	jalr	-678(ra) # 80001a24 <myproc>
    80006cd2:	89aa                	mv	s3,a0
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80006cd4:	14102af3          	csrr	s5,sepc
    char *pa = kalloc();
    80006cd8:	ffffa097          	auipc	ra,0xffffa
    80006cdc:	e80080e7          	jalr	-384(ra) # 80000b58 <kalloc>
    80006ce0:	892a                	mv	s2,a0
    copyin(p->pagetable, pa, addr, PGSIZE);
    80006ce2:	6685                	lui	a3,0x1
    80006ce4:	8656                	mv	a2,s5
    80006ce6:	85aa                	mv	a1,a0
    80006ce8:	0509b503          	ld	a0,80(s3)
    80006cec:	ffffb097          	auipc	ra,0xffffb
    80006cf0:	a84080e7          	jalr	-1404(ra) # 80001770 <copyin>
    uint32 inst     = *(uint32*)pa;
    80006cf4:	00092803          	lw	a6,0(s2)
    uint32 op       = inst & 0x7F;
    80006cf8:	07f87613          	andi	a2,a6,127
    uint32 rd       = (inst >> 7) & 0x1F;
    80006cfc:	0078569b          	srliw	a3,a6,0x7
    80006d00:	01f6fa13          	andi	s4,a3,31
    uint32 funct3   = (inst >> 12) & 0x7;
    80006d04:	00c8571b          	srliw	a4,a6,0xc
    80006d08:	8b1d                	andi	a4,a4,7
    uint32 rs1      = (inst >> 15) & 0x1F;
    80006d0a:	00f8579b          	srliw	a5,a6,0xf
    80006d0e:	8bfd                	andi	a5,a5,31
    uint32 uimm     = (inst >> 20) & 0xFFF;
    80006d10:	0148549b          	srliw	s1,a6,0x14
    if(funct3 == 0x0) {
    80006d14:	14071d63          	bnez	a4,80006e6e <trap_and_emulate+0x1b6>
        if(uimm == 0x0) {
    80006d18:	cca9                	beqz	s1,80006d72 <trap_and_emulate+0xba>
        else if(uimm == 0x102) {
    80006d1a:	10200713          	li	a4,258
    80006d1e:	0ce48a63          	beq	s1,a4,80006df2 <trap_and_emulate+0x13a>
        else if(uimm == 0x302) {
    80006d22:	30200713          	li	a4,770
    80006d26:	12e49a63          	bne	s1,a4,80006e5a <trap_and_emulate+0x1a2>
            if (vm_state.curr_mode > 1) {
    80006d2a:	0001c697          	auipc	a3,0x1c
    80006d2e:	c0e6b683          	ld	a3,-1010(a3) # 80022938 <vm_state+0x298>
    80006d32:	4705                	li	a4,1
    80006d34:	10d77963          	bgeu	a4,a3,80006e46 <trap_and_emulate+0x18e>
                printf("MRET (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
    80006d38:	30200813          	li	a6,770
    80006d3c:	4701                	li	a4,0
    80006d3e:	86d2                	mv	a3,s4
    80006d40:	85d6                	mv	a1,s5
    80006d42:	00002517          	auipc	a0,0x2
    80006d46:	14650513          	addi	a0,a0,326 # 80008e88 <v.0+0x340>
    80006d4a:	ffffa097          	auipc	ra,0xffffa
    80006d4e:	840080e7          	jalr	-1984(ra) # 8000058a <printf>
                unsigned long int mpp = (vm_state.mstatus.val >> 11) & 0x3;
    80006d52:	0001c717          	auipc	a4,0x1c
    80006d56:	94e70713          	addi	a4,a4,-1714 # 800226a0 <vm_state>
    80006d5a:	19873783          	ld	a5,408(a4)
    80006d5e:	83ad                	srli	a5,a5,0xb
    80006d60:	8b8d                	andi	a5,a5,3
                p->trapframe->epc = vm_state.mepc.val;
    80006d62:	0589b683          	ld	a3,88(s3)
    80006d66:	21873603          	ld	a2,536(a4)
    80006d6a:	ee90                	sd	a2,24(a3)
                vm_state.curr_mode = mpp;
    80006d6c:	28f73c23          	sd	a5,664(a4)
    80006d70:	a235                	j	80006e9c <trap_and_emulate+0x1e4>
            printf("ECALL (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
    80006d72:	4801                	li	a6,0
    80006d74:	86d2                	mv	a3,s4
    80006d76:	85d6                	mv	a1,s5
    80006d78:	00002517          	auipc	a0,0x2
    80006d7c:	07050513          	addi	a0,a0,112 # 80008de8 <v.0+0x2a0>
    80006d80:	ffffa097          	auipc	ra,0xffffa
    80006d84:	80a080e7          	jalr	-2038(ra) # 8000058a <printf>
            printf("(EC at %p)\n", p->trapframe->epc);
    80006d88:	0589b783          	ld	a5,88(s3)
    80006d8c:	6f8c                	ld	a1,24(a5)
    80006d8e:	00002517          	auipc	a0,0x2
    80006d92:	0a250513          	addi	a0,a0,162 # 80008e30 <v.0+0x2e8>
    80006d96:	ffff9097          	auipc	ra,0xffff9
    80006d9a:	7f4080e7          	jalr	2036(ra) # 8000058a <printf>
            if(vm_state.curr_mode == 0) {
    80006d9e:	0001c797          	auipc	a5,0x1c
    80006da2:	b9a7b783          	ld	a5,-1126(a5) # 80022938 <vm_state+0x298>
    80006da6:	e38d                	bnez	a5,80006dc8 <trap_and_emulate+0x110>
                vm_state.curr_mode = 1;
    80006da8:	0001c797          	auipc	a5,0x1c
    80006dac:	8f878793          	addi	a5,a5,-1800 # 800226a0 <vm_state>
    80006db0:	4705                	li	a4,1
    80006db2:	28e7bc23          	sd	a4,664(a5)
                vm_state.sepc.val = p->trapframe->epc;
    80006db6:	0589b703          	ld	a4,88(s3)
    80006dba:	6f18                	ld	a4,24(a4)
    80006dbc:	fff8                	sd	a4,248(a5)
                p->trapframe->epc = vm_state.stvec.val;
    80006dbe:	0589b703          	ld	a4,88(s3)
    80006dc2:	7fdc                	ld	a5,184(a5)
    80006dc4:	ef1c                	sd	a5,24(a4)
    80006dc6:	a8d9                	j	80006e9c <trap_and_emulate+0x1e4>
            else if(vm_state.curr_mode == 1) {
    80006dc8:	4705                	li	a4,1
    80006dca:	0ce79963          	bne	a5,a4,80006e9c <trap_and_emulate+0x1e4>
                vm_state.mepc.val = p->trapframe->epc;
    80006dce:	0589b783          	ld	a5,88(s3)
    80006dd2:	6f98                	ld	a4,24(a5)
    80006dd4:	0001c797          	auipc	a5,0x1c
    80006dd8:	8cc78793          	addi	a5,a5,-1844 # 800226a0 <vm_state>
    80006ddc:	20e7bc23          	sd	a4,536(a5)
                vm_state.curr_mode = 2;
    80006de0:	4709                	li	a4,2
    80006de2:	28e7bc23          	sd	a4,664(a5)
                p->trapframe->epc = vm_state.mtvec.val;
    80006de6:	0589b703          	ld	a4,88(s3)
    80006dea:	1a87b783          	ld	a5,424(a5)
    80006dee:	ef1c                	sd	a5,24(a4)
    80006df0:	a075                	j	80006e9c <trap_and_emulate+0x1e4>
            if (vm_state.curr_mode > 0) {
    80006df2:	0001c717          	auipc	a4,0x1c
    80006df6:	b4673703          	ld	a4,-1210(a4) # 80022938 <vm_state+0x298>
    80006dfa:	cf05                	beqz	a4,80006e32 <trap_and_emulate+0x17a>
                printf("SRET (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
    80006dfc:	10200813          	li	a6,258
    80006e00:	4701                	li	a4,0
    80006e02:	86d2                	mv	a3,s4
    80006e04:	85d6                	mv	a1,s5
    80006e06:	00002517          	auipc	a0,0x2
    80006e0a:	03a50513          	addi	a0,a0,58 # 80008e40 <v.0+0x2f8>
    80006e0e:	ffff9097          	auipc	ra,0xffff9
    80006e12:	77c080e7          	jalr	1916(ra) # 8000058a <printf>
                unsigned long sstatus = vm_state.sstatus.val;
    80006e16:	0001c717          	auipc	a4,0x1c
    80006e1a:	88a70713          	addi	a4,a4,-1910 # 800226a0 <vm_state>
                unsigned long spp = (sstatus >> 8) & 0x1; 
    80006e1e:	675c                	ld	a5,136(a4)
    80006e20:	83a1                	srli	a5,a5,0x8
    80006e22:	8b85                	andi	a5,a5,1
                p->trapframe->epc = vm_state.sepc.val;
    80006e24:	0589b683          	ld	a3,88(s3)
    80006e28:	7f70                	ld	a2,248(a4)
    80006e2a:	ee90                	sd	a2,24(a3)
                vm_state.curr_mode = spp;
    80006e2c:	28f73c23          	sd	a5,664(a4)
    80006e30:	a0b5                	j	80006e9c <trap_and_emulate+0x1e4>
                setkilled(p);
    80006e32:	854e                	mv	a0,s3
    80006e34:	ffffb097          	auipc	ra,0xffffb
    80006e38:	542080e7          	jalr	1346(ra) # 80002376 <setkilled>
                trap_and_emulate_init();
    80006e3c:	00000097          	auipc	ra,0x0
    80006e40:	c40080e7          	jalr	-960(ra) # 80006a7c <trap_and_emulate_init>
    80006e44:	a8a1                	j	80006e9c <trap_and_emulate+0x1e4>
                setkilled(p);
    80006e46:	854e                	mv	a0,s3
    80006e48:	ffffb097          	auipc	ra,0xffffb
    80006e4c:	52e080e7          	jalr	1326(ra) # 80002376 <setkilled>
                trap_and_emulate_init();
    80006e50:	00000097          	auipc	ra,0x0
    80006e54:	c2c080e7          	jalr	-980(ra) # 80006a7c <trap_and_emulate_init>
    80006e58:	a091                	j	80006e9c <trap_and_emulate+0x1e4>
            setkilled(p);
    80006e5a:	854e                	mv	a0,s3
    80006e5c:	ffffb097          	auipc	ra,0xffffb
    80006e60:	51a080e7          	jalr	1306(ra) # 80002376 <setkilled>
            trap_and_emulate_init();
    80006e64:	00000097          	auipc	ra,0x0
    80006e68:	c18080e7          	jalr	-1000(ra) # 80006a7c <trap_and_emulate_init>
    80006e6c:	a805                	j	80006e9c <trap_and_emulate+0x1e4>
    else if(funct3 == 0x1) {
    80006e6e:	4685                	li	a3,1
    80006e70:	04d70463          	beq	a4,a3,80006eb8 <trap_and_emulate+0x200>
    else if (funct3 == 0x2) {
    80006e74:	4689                	li	a3,2
    80006e76:	0ad70a63          	beq	a4,a3,80006f2a <trap_and_emulate+0x272>
        printf("ERROR: Incorrect instruction");
    80006e7a:	00002517          	auipc	a0,0x2
    80006e7e:	0fe50513          	addi	a0,a0,254 # 80008f78 <v.0+0x430>
    80006e82:	ffff9097          	auipc	ra,0xffff9
    80006e86:	708080e7          	jalr	1800(ra) # 8000058a <printf>
        setkilled(p);
    80006e8a:	854e                	mv	a0,s3
    80006e8c:	ffffb097          	auipc	ra,0xffffb
    80006e90:	4ea080e7          	jalr	1258(ra) # 80002376 <setkilled>
        trap_and_emulate_init();
    80006e94:	00000097          	auipc	ra,0x0
    80006e98:	be8080e7          	jalr	-1048(ra) # 80006a7c <trap_and_emulate_init>
    kfree(pa);
    80006e9c:	854a                	mv	a0,s2
    80006e9e:	ffffa097          	auipc	ra,0xffffa
    80006ea2:	bbc080e7          	jalr	-1092(ra) # 80000a5a <kfree>
}
    80006ea6:	60a6                	ld	ra,72(sp)
    80006ea8:	6406                	ld	s0,64(sp)
    80006eaa:	74e2                	ld	s1,56(sp)
    80006eac:	7942                	ld	s2,48(sp)
    80006eae:	79a2                	ld	s3,40(sp)
    80006eb0:	7a02                	ld	s4,32(sp)
    80006eb2:	6ae2                	ld	s5,24(sp)
    80006eb4:	6161                	addi	sp,sp,80
    80006eb6:	8082                	ret
        printf("CSRW (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
    80006eb8:	8826                	mv	a6,s1
    80006eba:	4705                	li	a4,1
    80006ebc:	86d2                	mv	a3,s4
    80006ebe:	85d6                	mv	a1,s5
    80006ec0:	00002517          	auipc	a0,0x2
    80006ec4:	01050513          	addi	a0,a0,16 # 80008ed0 <v.0+0x388>
    80006ec8:	ffff9097          	auipc	ra,0xffff9
    80006ecc:	6c2080e7          	jalr	1730(ra) # 8000058a <printf>
        struct vm_reg vr = find_reg(uimm);
    80006ed0:	8526                	mv	a0,s1
    80006ed2:	fffff097          	auipc	ra,0xfffff
    80006ed6:	740080e7          	jalr	1856(ra) # 80006612 <find_reg>
    80006eda:	faa43823          	sd	a0,-80(s0)
    80006ede:	fab43c23          	sd	a1,-72(s0)
        if(vr.val == -1){
    80006ee2:	57fd                	li	a5,-1
    80006ee4:	02f58063          	beq	a1,a5,80006f04 <trap_and_emulate+0x24c>
        if(vm_state.curr_mode >= vr.mode){
    80006ee8:	fb442783          	lw	a5,-76(s0)
    80006eec:	0001c717          	auipc	a4,0x1c
    80006ef0:	a4c73703          	ld	a4,-1460(a4) # 80022938 <vm_state+0x298>
    80006ef4:	02f76163          	bltu	a4,a5,80006f16 <trap_and_emulate+0x25e>
        p->trapframe->epc += 4;
    80006ef8:	0589b703          	ld	a4,88(s3)
    80006efc:	6f1c                	ld	a5,24(a4)
    80006efe:	0791                	addi	a5,a5,4
    80006f00:	ef1c                	sd	a5,24(a4)
    80006f02:	bf69                	j	80006e9c <trap_and_emulate+0x1e4>
            printf("Invalid Instruction");
    80006f04:	00002517          	auipc	a0,0x2
    80006f08:	01450513          	addi	a0,a0,20 # 80008f18 <v.0+0x3d0>
    80006f0c:	ffff9097          	auipc	ra,0xffff9
    80006f10:	67e080e7          	jalr	1662(ra) # 8000058a <printf>
            return;
    80006f14:	bf49                	j	80006ea6 <trap_and_emulate+0x1ee>
            setkilled(p);
    80006f16:	854e                	mv	a0,s3
    80006f18:	ffffb097          	auipc	ra,0xffffb
    80006f1c:	45e080e7          	jalr	1118(ra) # 80002376 <setkilled>
            trap_and_emulate_init();
    80006f20:	00000097          	auipc	ra,0x0
    80006f24:	b5c080e7          	jalr	-1188(ra) # 80006a7c <trap_and_emulate_init>
    80006f28:	bfc1                	j	80006ef8 <trap_and_emulate+0x240>
        printf("CSRR (PI at %p) op = %x, rd = %x, funct3 = %x, rs1 = %x, uimm = %x\n", 
    80006f2a:	8826                	mv	a6,s1
    80006f2c:	4709                	li	a4,2
    80006f2e:	86d2                	mv	a3,s4
    80006f30:	85d6                	mv	a1,s5
    80006f32:	00002517          	auipc	a0,0x2
    80006f36:	ffe50513          	addi	a0,a0,-2 # 80008f30 <v.0+0x3e8>
    80006f3a:	ffff9097          	auipc	ra,0xffff9
    80006f3e:	650080e7          	jalr	1616(ra) # 8000058a <printf>
        struct vm_reg vr = find_reg(uimm);
    80006f42:	8526                	mv	a0,s1
    80006f44:	fffff097          	auipc	ra,0xfffff
    80006f48:	6ce080e7          	jalr	1742(ra) # 80006612 <find_reg>
    80006f4c:	faa43823          	sd	a0,-80(s0)
    80006f50:	fab43c23          	sd	a1,-72(s0)
        if(vr.val == -1) {
    80006f54:	57fd                	li	a5,-1
    80006f56:	02f58863          	beq	a1,a5,80006f86 <trap_and_emulate+0x2ce>
        if(vm_state.curr_mode >= vr.mode){
    80006f5a:	fb442783          	lw	a5,-76(s0)
    80006f5e:	0001c717          	auipc	a4,0x1c
    80006f62:	9da73703          	ld	a4,-1574(a4) # 80022938 <vm_state+0x298>
    80006f66:	02f76963          	bltu	a4,a5,80006f98 <trap_and_emulate+0x2e0>
            *rd_ptr = reg_val;  
    80006f6a:	0589b783          	ld	a5,88(s3)
    80006f6e:	003a1693          	slli	a3,s4,0x3
    80006f72:	97b6                	add	a5,a5,a3
    80006f74:	1582                	slli	a1,a1,0x20
    80006f76:	9181                	srli	a1,a1,0x20
    80006f78:	f38c                	sd	a1,32(a5)
        p->trapframe->epc += 4;
    80006f7a:	0589b703          	ld	a4,88(s3)
    80006f7e:	6f1c                	ld	a5,24(a4)
    80006f80:	0791                	addi	a5,a5,4
    80006f82:	ef1c                	sd	a5,24(a4)
    80006f84:	bf21                	j	80006e9c <trap_and_emulate+0x1e4>
            printf("Invalid Instruction");
    80006f86:	00002517          	auipc	a0,0x2
    80006f8a:	f9250513          	addi	a0,a0,-110 # 80008f18 <v.0+0x3d0>
    80006f8e:	ffff9097          	auipc	ra,0xffff9
    80006f92:	5fc080e7          	jalr	1532(ra) # 8000058a <printf>
            return;
    80006f96:	bf01                	j	80006ea6 <trap_and_emulate+0x1ee>
            setkilled(p);
    80006f98:	854e                	mv	a0,s3
    80006f9a:	ffffb097          	auipc	ra,0xffffb
    80006f9e:	3dc080e7          	jalr	988(ra) # 80002376 <setkilled>
            trap_and_emulate_init();
    80006fa2:	00000097          	auipc	ra,0x0
    80006fa6:	ada080e7          	jalr	-1318(ra) # 80006a7c <trap_and_emulate_init>
    80006faa:	bfc1                	j	80006f7a <trap_and_emulate+0x2c2>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
