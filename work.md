# Лабораторная работ 2. Симуляция SCR1
## Постановка задачи
| ФИО | Вид исключения | Тест | Reset Vector | Trap Vector | Обработчик |
|---|---|---|---|---|---|
| Даниил Симоновский | Instruction address misaligned | isa/rv32mi/ma_fetch.S | 0x200 | 0x400 | Вывод строки «misalign trap» |
## Выполнение ЛР
### Установка репозитория
Первым делом выполню форк репозитория [SCR1](https://github.com/v-crys/scr1) в свой github аккаунт.  
В данном репозитории размещён исходный код открытого ядра SCR1 на архитектуре RISC-V, разрабатываемого Syntacore на языке Verilog.  
Выполним клонирование форкнутого репозитория на компьютер:
```bash
git clone https://github.com/DafterT/lab_scr1.git
cd ./lab_scr1
git submodule update --init --recursive
git checkout -b lab_scr1_sim
```
### Первая сборка проекта
После этого откроем VSCode, на рабочей машине уже стоят все необходимые зависимости.  
Укажем путь до тулчейна:
```bash
export PATH=/home/dafter/riscv-tools/riscv-gcc-10.2.0-gbbc9263-210318T1412/bin/:$PATH
```
Выполним первую сборку проекта:
```bash
make TARGETS="riscv_isa"
```
В результате получаю сообщение об ошибке:
```
Assembler messages:
Fatal error: -march=rv32imfc_zicsr_zifencei: Invalid or unknown z ISA extension: 'zifencei'
make[1]: *** [Makefile:33: /mnt/c/Users/User/Downloads/lab_scr1/build/verilator_AHB_MAX_imc_IPIC_1_TCM_1_VIRQ_1_TRACE_0/riscv_objs/add.o] Error 1
make[1]: Leaving directory '/mnt/c/Users/User/Downloads/lab_scr1/sim/tests/riscv_isa'
make: *** [Makefile:219: riscv_isa] Error 2
```
В нем говорится, что текущий тулчейн не поддерживает расширение `zifencei` причина в том, что установленная версия тулчейна - 2.35:
```bash
dafter@DESKTOP-7INI93R:/mnt/c/Users/User/Downloads/lab_scr1$ riscv64-unknown-elf-ld -v
GNU ld (GNU Binutils) 2.35
```
А расширение появилсоь только в 2.36. Однако это не станет проблемой, поскольку расширение `Zifencei` добавляет в ISA только инструкцию `fence.i`, которая в более старых версиях спецификации RISC-V считалась частью базового набора I, поэтому тулчейн 2.35 поддерживает её ассемблирование без явного указания расширения в `-march`. Для успешной сборки достаточно удалить суффикс `_zifencei` из флагов `CFLAGS` и `LDFLAGS` в `Makefile`, оставив `-march=rv32imfc_zicsr`.  
Обновив флаги в `sim\tests\riscv_isa\Makefile`, выполним повторную сборку:
```bash
make clean
make TARGETS="riscv_isa"
```
После сборки были запущены тесты, которые завершились успешно:
```
#--------------------------------------
# Summary: 56/56 tests passed
#--------------------------------------
```
### Вектор прерываний, ресетов и настройка линковщика
После успешной сборки проекта необходимо выполнить модификацию в соответствии с заданием.  
Начать стоит с SCR1_ARCH_RST_VECTOR и SCR1_ARCH_MTVEC_BASE которые зедаются в `src\includes\scr1_arch_description.svh`  
Эти параметры отвечают за следующие функции:
 - `SCR1_ARCH_RST_VECTOR` - адрес первой инструкции, с которой процессор начинает выполнение после сброса (reset vector). По умолчанию `0x200` — это «точка входа» программы после включения/перезагрузки ядра.
 - `SCR1_ARCH_MTVEC_BASE` - базовый адрес обработчика исключений и прерываний, который записывается в CSR-регистр mtvec при reset. По умолчанию `0x1C0` — это адрес, куда процессор будет переходить при возникновении trap или interrupt.  

Выполним модификацию и зададим им значения в соответствии с вариантом:
```svh
parameter bit [`SCR1_XLEN-1:0] SCR1_ARCH_RST_VECTOR = 'h200;
parameter bit [`SCR1_XLEN-1:0] SCR1_ARCH_MTVEC_BASE = 'h400;
```
Теперь нужно обновить линковщик для корректного размещения обработчика trap и стартового кода по адресам, которые заданы в параметрах ядра. Для этого в скрипте линковки явно указываются новые базовые адреса: секция `.text.init` (trap_vector) должна начинаться с адреса, равного MTVEC_BASE, а секция `.text.start` — с адреса, равного RST_VECTOR. Такой подход гарантирует, что при возникновении исключения или после сброса ядро всегда перейдёт к нужному коду.

Изменения в файле `sim/tests/common/link.ld`  
Заменим строку:
```ld
. = 0x100;
PROVIDE(__TEXT_START__ = .);
*(.text.init)
```
На:
```
. = 0x400;
PROVIDE(__TEXT_START__ = .);
*(.text.init)
```
Теперь секция `.text.init`, содержащая код `trap_vector`, будет размещена начиная с адреса `0x400`, что соответствует значению `SCR1_ARCH_MTVEC_BASE = 'h0400`. Теперь ядро при возникновении исключения перейдёт точно по адресу 0x500, где будет лежать наш обработчик.

Также добавим новую секцию после блока `.text.init`:
```
.text.start 0x200 : {
   PROVIDE(__TEXT_END__ = .);
   PROVIDE(__TEXT_START__ = .);
   *(.text.start)
} >RAM
```
Это создаст отдельную секцию `.text.start` с базовым адресом `0x200`, что соответствует значению `SCR1_ARCH_RST_VECTOR = 'h200`. До этого `_start` размещался в общей секции `.text` неявно, теперь точка входа программы гарантированно будет лежать по адресу `0x200`, откуда ядро начнёт выполнение после сброса.  
Поместим код в секцию `.text.start`, для этого в файл `sim\tests\common\riscv_macros.h` перед `_start:` добавим обозначение секции:
```h
_report:                                                                \
        j sc_exit;                                                      \
        .balign  64;                                                    \
        .globl _start;                                                  \
        .section .text.start;                                           \
_start:   
```
Таким образом мы изменили адреса trap вектора и адреса ресета. Выполним сборку:
```bash
make clean
make TARGETS="riscv_isa"
```
В результате получаем следующую ошибку:
```
section .text.start LMA [0000000000000200,0000000000000261] overlaps section .text.init LMA [0000000000000000,0000000000000511]
```
Здесь написано, что секция .text.start накладывается на секцию .text.init. 
Попробуем исправить это и обновим линковщик, явно задав место в памяти для trap vector:
```
  .text.head 0 : { 
    FILL(0);
    . = 0x100 - 12;
    SIM_EXIT = .;
    LONG(0x13);
    SIM_STOP = .;
    LONG(0x6F);
    LONG(-1);
  } >RAM

  .text.start 0x200: { 
    *(.text.start) 
  } >RAM

  .text.init 0x400 : {
      *(.text.init)
  } >RAM
```
Выполним сборку и проверим, все ли работает:
```bash
make clean
make TARGETS="riscv_isa"
```
После сборки все тесты прошли успешно!
### Обновление обработчика исключений