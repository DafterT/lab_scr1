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
Обновив флаги, выполним повторную сборку:
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
### 