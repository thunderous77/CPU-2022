# CPU Design

by thunderous

## Outline

<img src="D:\Sam\program\CPU-2022\CPU-design.png" style="zoom:30%">

架构指南：

[记分牌算法](https://zhuanlan.zhihu.com/p/496078836)

[Tomasulo算法](https://zhuanlan.zhihu.com/p/499978902)

[Reorder Buffer](https://zhuanlan.zhihu.com/p/501631371)

[branch prediction](https://zhuanlan.zhihu.com/p/490749315)

## MemCtrl

* load/store 指令的 cycle 数都是 size+1

  > load 时需要先给 ram 传参，等一个 cycle 再非阻塞赋值（compulsory）
  
  > store 传出最后一组数据后也需要等一个cycle让ram存储
  
* rollback 时除 store 之外全部清空

* rollback 时储存数据一个周期后再修改，但是利用 shadow 立刻传递这个信息

## RS



## ROB

![img](https://pic3.zhimg.com/v2-252534106244ab82292e5b856f296a06_r.jpg)

* invalid 位设计

  ```verilog
  "define.v"
  // Reorder Buffer(ROB)
  // ZERO_ROB -> INVALID 
  // VALID ROB -> 5'd1 - 5d'16
  `define ZERO_ROB 4'h0
  `define ROB_SIZE 16
  `define ROB_ID_TYPE 4:0
  `define ROB_POS_TYPE 3: 0
  ```

  not busy 的 register（data 是 valid 的）对应的 ROB 为 ZERO_ROB，其余对应 5'd1-5'h16 的 16 个ROB

  因此 ROB_ID 需要 17 个，需要 5 位，而 ROB_POS 则是 ROB 内部数据，只需要 16 位

##  Decoder

![img](https://img-blog.csdnimg.cn/20210514222917648.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3FxXzM4OTE1MzU0,size_16,color_FFFFFF,t_70)

[RISC-V指令集](https://blog.csdn.net/qq_38915354/article/details/115696721)

## Register

* 当 ROB 提交寄存器与 rd 对应寄存器相同时，数据是 invalid 的，但是不一定不能用。特殊情况如下：

  > rs1 = rd = rob 时，例如指令 X 对寄存器 A 执行加 1，同时 ROB commit 的指令 Y 也是修改寄存器 A，此时如果询问 Q1 应返回 INVALID_ROB，因为实际上指令 X 的初值已经修改好了
