## IF Stage

1. PC -> I-Memory -> Instruction: 一共有 2 个 cycle 的 delay，需要保证 PC 和 instruction 在流水线上是匹配的，在代码里使用了一个额外的`pc_instru`寄存器来提供额外一个 cycle 的 PC 延迟

2. 当流水线刷新之后，新地址对应的指令在 2 个 cycle 之后送到 ID Stage，因此其后续两个 cycle 的指令都是无效指令，看作 2 条 nop 指令

   ![image-20230510125035631](https://s2.loli.net/2023/05/10/1J3dMl7xNAnV4tK.png)


## ID Stage

1. RF(register File)异步读出、同步写入

## EXE Stage

## MEM Stage

1. MEM 和 EXE 需要 resetn 信号，否则 reset 之后的`reg_wb_en`会是 x，导致第一次读取 RF 时读出的也是 x

## WB Stage

1. 由于 ID 级的 RF 需要一个 cycle 才可以写入，因此 WB Stage 的 output 被定义为 wire 类型，从而避免额外一个 cycle 的 RF 写入延迟，此时 WB 变成纯组合逻辑
2. TODO: delete wb pipeline register
