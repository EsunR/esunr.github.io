---
title: PHP文件操作以及文件的上传与下载
tags: []
categories:
  - Back
  - PHP
date: 2020-01-02 14:20:59
---
# 1. 获取文件信息

`is_file(string $filePath): bool` 可以用来判断是否是文件类型，返回一个布尔类型：

```php
is_file('./text.txt')
```

`is_dir(string $dirPath): bool`  可以用来判断是否是文件夹，返回一个布尔值：

```php
is_dir('./floder')
```

`filesize(string $filePath): int` 用来获取文件的大小，返回一个字节大小

`is_readable(string $filePath): bool` 判断文件是否可读写

`is_writeable(string $filePath): bool` 判断文件是否可读写

`filectime(string $filePath): int` 获取文件创建时间，返回一个时间戳：

```php
date_default_timezone_set('Asia/Shanghai');
echo date('Y-m-d G:i:s', filectime('index.php')); // 2019-12-31 16:16:22
```

`filemtime(string $filePath): int` 获取文件的修改时间，返回一个时间戳

`fileatime(string $filePath): int` 获取文件的修改时间，返回一个时间戳

`stat()` 可以获取到文件的信息，返回是一个数组，用来表示信息

# 2. 目录的基本操作

`basename(string $filePath): string` 返回路径中的文件名部分:

```php
echo __FILE__; // /var/www/html/php/demo.php
echo basename(__FILE__) // demo.php
```

`dirname(string $filePath): string` 返回路径的目录部分

`pathinfo(string $filePath): string` 返回文件路径的信息：

```
// 返回示例：
array(4) {
  ["dirname"]=>
    string(22) "/var/www/html/php/file"
  ["basename"]=>
    string(6) "03.php"
  ["extension"]=>
    string(3) "php"
  ["filename"]=>
    string(2) "03"
}
```

`opendir(string $dirPath): resource` 打开目录句柄：

```php
$dirHandler = opendir('./testDir');
```

`readdir(resource $dirHandler): string` 从目录句柄中读取条目，返回目录中下一个文件的文件名

`rewinddir(resource $dirHandler): void` 倒回目录句柄

`closedir(resource $dirHandler): void` 关闭目录句柄

`mkdir (string $pathname [, int $mode = 0777 [, bool $recursive = false [, resource $context ]]] ): bool` 新建目录，返回一个布尔值：

```php
mkdir('dir/subdir/subsubdir', 0777, true); // 可创建多层目录
```

`scandir ( string $directory [, int $sorting_order [, resource $context ]] ) : array` 返回文件中的所有文件：

```php
var_dump(scandir('./'));
/*
array(9) {
  [0]=>
    string(1) "."
  [1]=>
    string(2) ".."
  [2]=>
    string(6) "01.php"
  [3]=>
    string(6) "02.php"
  [4]=>
    string(6) "03.php"
  [5]=>
    string(6) "04.php"
  [6]=>
    string(3) "dir"
  [7]=>
    string(8) "text.txt"
  [8]=>
    string(15) "文件操作.md"
}
*/
```

# 3. 文件的基本操作

`fopen ( string $filename , string $mode [, bool $use_include_path = false [, resource $context ]] ) : resource` 打开文件或者 URL，返回一个资源句柄

`fread ( resource $handle , int $length ) : string` 传入文件句柄以及读取的字节数，返回读取的内容：

```
# test.txt
abc哈
哈哈哈哈
abcabc
```

```php
header('Content-type:text/html;charset=utf-8'); // 设置浏览器的 ContentType 信息
$file = fopen('test.txt', 'r'); // 以只读方式打开
var_dump(fread($file,1)); // string(1) "a"
var_dump(fread($file,1)); // string(1) "b"
var_dump(fread($file,1)); // string(1) "c"
var_dump(fread($file,3)); // string(3) "哈" （中文占用三个字节）
var_dump(fread($file,1)); // string(0) ""
```

`fget ( resource $handle ) : string` 从文件指针中读取一行，返回读取的字符串，如果文件读取完毕返回一个 false：

```php
<?php
$file = fopen('test.txt', 'r'); // 以只读方式打开
var_dump(fgets($file)); // string(7) "abc哈"
var_dump(fgets($file)); // string(13) "哈哈哈哈"
var_dump(fgets($file)); // string(6) "abcabc"
var_dump(fgets($file)); // bool(false)
```

`feof ( resource $handle ) : bool` 测试文件指针是否到了文件结束的位置

`fwrite ( resource $handle , string $string [, int $length ] ) : int` 写入文件，返回写入的字节数，其写入的内容会覆盖原有的内容

`fseek ( resource $handle , int $offset [, int $whence = SEEK_SET ] ) : int` 在文件指针中定位：

```php
$file = fopen('test.txt', 'r+'); // 以可写模式打开文件
// 在文件末尾写入内容
fseek($file, 0, SEEK_END); 
fwrite($file, '新内容');
```

也可以使用其他方式定位文件到尾部：

```php
$file = fopen('test.txt', 'a+'); // 定位到尾部打开文件
fwrite($file, '新内容');
```

`rewind ( resource $handle ) : bool` 倒回文件指针的位置

`flock ( resource $handle , int $operation [, int &$wouldblock ] ) : bool` 轻便的咨询文件锁定：

```php
$file = fopen("text.txt", "a+");
// 文件加锁
if (flock($file, LOCK_EX)) {
  var_dump(fwrite($file, "啦啦啦"));
  flock($file, LOCK_UN); // 文空解锁，脚本执行完毕后也会自动解锁
} else {
  echo "文件加锁失败";
}
```

`file ( string $filename [, int $flags = 0 [, resource $context ]] ) : array` 把整个文件读入一个数组中

`copy ( string $source , string $dest [, resource $context ] ) : bool` 拷贝文件

`unlink ( string $filename [, resource $context ] ) : bool` 删除文件

`file_get_contents ( string $filename [, bool $use_include_path = false [, resource $context [, int $offset = -1 [, int $maxlen ]]]] ) : string` 将整个文件读入一个字符串
 
`file_put_contents ( string $filename , mixed $data [, int $flags = 0 [, resource $context ]] ) : int` 将一个字符串写入文件：

```php
file_put_contents("test.txt", file_get_contents("http://www.esunr.xyz"));
```

`rename ( string $oldname , string $newname [, resource $context ] ) : bool` 重命名一个文件或目录

`readfile ( string $filename [, bool $use_include_path = false [, resource $context ]] ) : int` 读取文件并写入到输出缓冲


# 4. 文件的上传

关于文件上传，在 `php.ini` 中必须开启相关的设置，默认配置是会开启允许上传的，我们可以修改上传文件所允许的大小，其选项的缺省值入下：

![](http://study.esunr.xyz/1577935940955.png)

使用表单上传文件到 php 脚本后，可以使用 `$_FILES` 获取上传文件的信息：

![](http://study.esunr.xyz/1577939066633.png)

`is_uploaded_file ( string $filename ) : bool` 判断文件是否是通过 HTTP POST 上传的，传入文件路径

`move_uploaded_file ( string $filename , string $destination ) : bool` 将上传的文件移动到新位置

完整的服务器端上传接口示例：

```php
<?php
header("Content-type: application/json; charset=utf-8");
try {
  $fileInfo = $_FILES["file"]; // 表单中的 key
  $tmpName = $fileInfo["tmp_name"];
  $fileName = $fileInfo["name"];
  // 检测是否通过 post 上传
  if (is_uploaded_file($tmpName)) {
    $moveResult = move_uploaded_file($tmpName, "./static/" . $fileName);
    $result = [
      "upload_file" => $_FILES,
      "moveResult" => $moveResult
    ];
    echo json_encode($result);
  } else {
    exit("没有使用 POST 请求或上传文件错误");
  }
} catch (Exception $e) {
  var_dump($e);
}
```

返回成功示例：

```json
{
  "upload_file": {
    "file": {
      "name": "30311024.jpg",
      "type": "image/jpeg",
      "tmp_name": "/tmp/phpEetT2V",
      "error": 0,
      "size": 3535
    }
  },
  "moveResult": true
}
```

# 5. 文件的下载

当我们下载文件时可以通过访问文件的 url，但是在某些情况下我们不希望将文件的 url 暴露给用户，所以我们希望通过访问一个 php 脚本，让这个脚本返回用户将要下载的文件，这样也可以方便我们动态返回文件：

首先需要开启 `fileinfo` 插件，需要使用到如下的方法：

`finfo_open ([ int $options = FILEINFO_NONE [, string $magic_file = NULL ]] ) : resource` 创建一个 fileinfo 资源

`finfo_file ( resource $finfo , string $file_name = NULL [, int $options = FILEINFO_NONE [, resource $context = NULL ]] ) : string` 返回一个文件的信息

`finfo_close ( resource $finfo ) : bool` 关闭 fileinfo 资源

通过以上的三个 API 可以获取到文件的信息，这样我们就可以通过设置 http header 以及使用 `readfile()` 方法来将文件输出给客户端，以下是一个完整示例：

```php
<?php
$file = "./static/30311024.jpg";
$fileinfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($fileinfo, $file);
finfo_close($fileinfo);
// 指定类型
header('Content-type:' . $mimeType);
// 指定下载文件的描述
header('Content-Disposition: attachement; filename=' . basename($file));
// 指定文件的大小
header('Content-Length:' . filesize($file));
// 读取文件内容输出到缓冲区，返回这个文件
readfile($file);
```
