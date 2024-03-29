---
title: PHP语法基础
tags:
  - PHP
categories:
  - 后端
  - PHP
date: 2019-12-12 20:39:27
---
# 1. 变量

## 1.1 变量定义

PHP 中的变量不需要任何赋值关键字，直接使用 `$` 即可创建一个变量：

```php
$var1;      // 定义变量
$var2 = 1;  // 定义并赋值
echo $var2; // 输出变量
```

定义变量后如果不适用就需要删除变量：

```php
unset($var2);
echo($var2);  // Udefined variable
```

变量定义规则：

- 必须以 `$` 开始
- 变量可以有数字、字母、下划线，但是不能以数字开头，如 `$1var`
- PHP 允许使用中文变量

## 1.2 预定义变量

- $_GET
- $_POST
- $_REQUEST
- $GLOBALS
- $_SERVER：服务器信息
- $_SESSION
- $_COOKIE
- $_ENV
- $_FILES

## 1.3 可变变量

如果 `$` 后紧跟一个带有 `$` 的变量，变量的值为另一个变量的名字，则可以通过第一个 `$` 取到相应变量的值，如：

```php
$a = 'b'
$b = 'result'
echo $$a      // 'result'
```

原理：`$a` => 'b'， `$` 与 `'b'` 绑定 => `$b` => 'result'

## 1.4 变量传值

值传递：

```php
$a = 1;
$b = $a;  

$b = 2;
echo $a, $b;    // 1,2
```

引用传递：

```php
$a = 1;
$b = &$a;

$b = 2;
echo $a, $b   // 2, 2 
```

# 2. 常量

## 2.1 常量的定义

两种方式：

```php
define('常量名', 常量值, [是否区分大小写]); 
const 常量名 = 值;  // php 5.3+
```
 
特殊常量仅能使用 `define()` ，如：

```php
define('-_-', 'smile');
// const -_- = 'smile' 错误
```

`define` 与 `const` 定义常量的区别再于 **访问权限** 。

对于特殊常量我们需要使用 `constant()`：

```php
define('-_-', 'smile');
// echo -_- 错误
echo constant('-_-') // 'smile'
```

## 2.2 系统常量

常用常量：

- PHP_VERSION
- PHP_INT_MAX
- PHP_INT_SIZE：表示整型所占用的字节数，值为4，PHP中整型允许负数

> 整数类型由 4 个字节存放，也就是 32 位，转化为十进制后可以表达的最大数为 `4294967295` ，但是 PHP 的的 `PHP_INT_MAX` 只有 `2147483647`，这是因为 PHP 需要用一个符号位来表示负数，因此实际上用来表示数字的占 31 位。

> 在 64 位的 PHP 中，PHP_INT_SIZE 为 8，相应的 PHP_INT_MAX 也更大。

魔术常量：

- \_\_DIR\_\_：当前被执行脚本所在的绝对路径
- \_\_FILE\_\_：当前被执行脚本的绝对路径（带名字）
- \_\_NAMESPACE\_\_：当前所属的行数
- \_\_CLASS\_\_：当前所属的类
- \_\_METHOD\_\_：当前所属的方法

# 3. 数据类型

data type 在 PHP 中指的是数据本身的类型，而不是变量的类型，PHP是一种弱语言类型，本身没有数据类型。

## 3.1 八种数据类型

PHP 的数据类型可分为三大类八小类。

**简单/基本数据类型（4个小类）：**

- 整型 int/integer：4个字节存储，如果超出存储范围，会被转为浮点型存储
- 浮点型 float/double：8个字节存储
- 字符串型 string：根据系统长度分配
- 布尔类型 bool/boolean

**复合数据类型（2小类）：**

- 资源类型 resource：存放资源数据（PHP 外部数据，如数据库、文件）
- 空类型 NULL：只有一个值就是 NULL 

## 3.2 类型转换

PHP 中有两种类型的转换方式：

自动转换：系统自行转换，效率较低

```php
$a = 'abc1.1.1';
$b = '1.1.1abc';

echo $a + $b; // 1.1
```

强制转换：根据自己的需要将目标类型转换

```php
$a = 'abc1.1.1';
$b = '1.1.1abc';

echo (float)$a, (float)$b; // 01.1
echo $a; // 'abc1.1.1'
```

同时还可以使用 `settype()` 方法对变量进行强制转换，这会对原来的值产生影响:

```php
$b = '1.1.1abc';
settype($b, 'int');
echo $b; // 1
```

![](http://img.cdn.esunr.xyz/markdown/20191212104623.png)

其他类型转数据值的说明：

- 布尔 true 为 1，false 为0
- 字符串数据有自己的规则
  - 以字母开头的字符，永远为0
  - 数字开头的字符，取碰到字符前的数字部分

## 3.3 类型判断

使用 `is_` 判断，结果返回一个布尔值，但由于 Bool 类型不能用 `echo` 来查看，所以要使用 `var_dump` 结构来查看：

```php
$a = '123';
var_dump(is_int($a)); // false
var_dump(is_string($a)); // false
```

使用 `gettype()` 方法也可以用来获取类型，得到是该类型对应的字符串：

```php
$a = '123';
echo gettype($a); // string
```

## 3.4 数字类型

不同的进制表示方法如下：

- `$a = 120;` 十进制
- `$a = 0b110;` 二进制，以 `0b` 开头
- `$a = 0120;` 八进制，以 `0` 开头
- `$a = 0x120;` 十六进制，以 `0x` 开头

对于浮点型型，计算可能不准确：

```php
$f = 2.1;
var_dump($f / 3 == 0.7); // bool(false)
```

同时还可以使用如下的方法判断数据是否为空：

- `empty()`: 判断数据的值是否为空，如空字符串、null、空数组、布尔值为 false 的、未定义的变量，返回都是 `true`
- `isset()`：判断数据存储的变量值本身是否存在，如变量值为 null 的、变量定义却未赋值的、未定义的变量，返回都是 `false`
- `is_null`：与 `isset` 的定义正好相反

# 4. 运算

## 4.1 连接运算符

使用 `.` 可以将变量连接起来：

```php
$a = 'hello';
$b = 123;

echo $a . $b; // hello 123

$a .= $b;
echo $a; // hello 123
```

## 4.2 错误抑制符

使用 `@` 可以抑制报错，使代码继续向后执行：

```php
$a = 233;
@( $a / 0 );
echo $a; // 233
```

## 4.3 三元运算符

支持

## 4.4 逻辑运算

与 Javascript 用法一致

## 4.5 位运算符

- `&` 按位与，两个位都未1，结果为1，否则为0
- `|` 按位或，两个有一个为1，结果为1
- `~` 按位非，一个位如果为1则变成0，否则反之
- `^` 按位异或，两个相同则为0，不同则为1
- `<<` 按位左移，整个位（32位）
- `>>` 按位右移

举例1：

```php
$a = 5; 
$b = -5;
var_dump($a & $b); // int(1)
```

原理：

```
 5 的源码：00000101  
-5 的源码：11111010  
 & 的运算：00000001
```

举例2：

```php
$a = -5;
var_dump($a >> 2); // int(-2)
```

原理：

```
-5   11111011
>>1  11111110 // 运算结果：补码
-1   11111101 // 反码
取反  10000010 // 原码：-2
```

# 5. 循环

for 循环：

```php
for($i = 0; $i < 3; $i++){
  echo $i . "<br>";
}
```

```
0
1
2
```

foreach 循环：

```php
$x = array("one","two","three");
foreach ($x as $value){
  echo $value . "<br>";
}
```

```
one
two
three
```

while 循环：

```php
while($i<=5){
  echo "The number is " . $i . "<br>";
  $i++;
}
```

```
The number is 1
The number is 2
The number is 3
The number is 4
The number is 5
```

do...while 循环：

```php
do {
  $i++;
  echo "The number is " . $i . "<br>";
}
while ($i<=5);
```

```
The number is 2
The number is 3
The number is 4
The number is 5
The number is 6
```

# 5. 函数

创建函数：

```php
function functionName($name){
  echo $name;
}
functionName("huahua"); // 'huahua'
```

默认参数：

```php
function setHeight($minheight=50) {
  echo "The height is : $minheight <br>";
}
```

# 6. 数组

## 6.1 数组

创建数组：

```php
$cars = array("porsche","BMW","Volvo");
echo $cars[0];
var_dump ($cars);
```

```
porsche

array(3) {
  [0]=>
  string(7) "porsche"
  [1]=>
  string(3) "BMW"
  [2]=>
  string(5) "Volvo"
}
```

> php 中的数组是值类型的。

## 6.2 关联数组

创建关联数组：

```php
$age = array("Bill"=>"35","Steve"=>"37","Elon"=>"43");
echo $age['Elon']; // 43
```

从 PHP 5.4 起可以使用：

```php
$array = [
    "foo" => "bar",
    "bar" => "foo",
];
```

遍历关联数组：

```php
foreach ($age as $x=>$x_value) {
  echo "Key=" . $x . ", Value=" . $x_value;
  echo "<br>";
}
```