#!/usr/bin/env python
# -*- coding:utf-8 -*- 

#install path
#--base_path/running/service/pool:
#                     |--bin  --->service's bin path
#                     |     |--start.sh  --->start service
#                     |     |--stop.sh   --->stop service
#                     |     |--install.sh --->install service
#                     |--other path    -->other path for service
#                     |--.install
#                     |     |--bin
#                     |     |   |--apollo_app_service.sh
#                     |     |--version  --->service's version file for running
#                     |     |--history  --->history package path
#                     |     |    |--pkg
#                     |     |    |   |---project_service_version.tar.gz
#                     |     |    |--env
#                     |     |    |   |--project_service_pool_version.tar.gz
#                     |     |--tmp  --->temporary path
#                     |        |--env --->service's pool's env conf
#                              |--other file
import os
import commands
import shutil
import sys
import traceback
import datetime
import platform
import ConfigParser
import hashlib
import pwd
import getpass
RESERVE_PACKAGE_NUM = 3

class DcmdInstall():
  def __init__(self):
    """ Init
    """
    #self.app_name_ = os.environ.get('DCMD_APP_NAME')   
    #self.svr_name_ = os.environ.get('DCMD_SVR_NAME')
    #self.svr_pool_ = os.environ.get('DCMD_SVR_POOL')
    self.app_name_ = "search"
    self.svr_name_ = "rbs"
    self.svr_pool_ = "test_dalu"
    self.svr_repo_ = os.environ.get('DCMD_SVR_REPO')
    #self.svr_user_ = os.environ.get('DCMD_SVR_USER')
    self.svr_user_ = "search"
    self.svr_ip_ = os.environ.get('DCMD_SVR_IP')
    self.svr_env_md5_ = os.environ.get('DCMD_SVR_ENV_MD5')
    self.svr_env_passwd_ = os.environ.get('DCMD_SVR_ENV_PASSWD')
    #self.svr_script_ = os.environ.get('DCMD_SVR_SCRIPT_FILE')
    self.svr_script_ = "/letv/dockertest/dcmd_svr_search_docker.script"
    #self.svr_result_file_ = os.environ.get('DCMD_SVR_RESULT_FILE')
    self.svr_result_file_ = "/letv/dockertest/out.result"
    #self.is_svr_update_env_ = True if "1"== os.environ.get('DCMD_SVR_UPDATE_ENV') else False
    self.is_svr_update_env_ = False
    
    self.is_svr_process_ = True if "1"== os.environ.get('DCMD_SVR_PROCESS') else False
    self.svr_env_v_ = os.environ.get('DCMD_SVR_ENV_V')
    self.svr_env_v_ = ""
    #self.svr_path_ = os.environ.get('DCMD_SVR_PATH')
    self.svr_path_ = "/letv/dockertest"
    self.svr_node_mutil_pool_ = True if "1"== os.environ.get('DCMD_SVR_NODE_MUTIL_POOL') else False
    self.svr_script_file_ = os.environ.get('DCMD_SVR_SCRIPT_FILE')
    self.agent_pid_ = os.environ.get('DCMD_SYS_AGENT_PID')
    self.agent_ppid_ = os.environ.get('DCMD_SYS_AGENT_PPID')
    self.svr_home_ = os.path.join(self.svr_path_,"running", self.svr_name_, self.svr_pool_)
    self.install_path_ = os.path.join(self.svr_home_, ".install")
    self.install_bin_ = os.path.join(self.svr_home_, ".install", "bin")
    self.svr_history_env_path_  = os.path.join(self.install_path_, "history","env")
    self.svr_version_file_ = os.path.join(self.install_path_, "version")
    self.svr_tmp_path_ = os.path.join(self.install_path_, "tmp")
    self.svr_tmp_env_path_ = os.path.join(self.install_path_, "tmp","env") 
    
    self.svr_online_image_file_ = ""
    self.svr_online_image_tag_ = ""
    
    self.svr_online_env_version_ = ""
    self.svr_online_env_md5_ = ""
    
    self.install_errmsg_ = ""
    self.install_success_ = False
    self.svr_env_pkg_file_ = "conf_%s_%s_%s_%s_%s.tar.gz" % (self.app_name_, self.svr_name_, self.svr_pool_, self.svr_env_v_, self.svr_env_md5_[0:16])
    self.svr_env_pkg_pathfile_ = "%s/%s/conf/%s/%s" % (self.app_name_, self.svr_name_, self.svr_pool_, self.svr_env_pkg_file_) 
    self.is_update_env_ = True
    
    self.is_update_image_ = True
    self.svr_project_name_ = "%s" % (self.app_name_)
    self.svr_image_file_ = "%s_%s" % (self.app_name_, self.svr_name_)
    self.svr_image_tag_ = "latest" if not os.environ.get('DCMD_SVR_SYS_svr_version') else os.environ.get('DCMD_SVR_SYS_svr_version')
    self.svr_container_name_ = "%s_%s_%s" % (self.app_name_, self.svr_name_, self.svr_pool_)
    self.svr_docker_harbor_ip_ = "10.185.31.142"
    self.svr_reg_user_ = os.environ.get('DCMD_SVR_REG_USER')
    self.svr_reg_passwd_ = os.environ.get('DCMD_SVR_REG_PASSWD')
    


  def clean_path(self, path):
    """ 清空path下的任何文件及目录
    """
    print("Clear path:%s" % path)
    files = os.listdir(path)
    for f in files:
      rm_file = os.path.join(path, f)
      self._remove(rm_file)

  def remove_outdate_pkg(self, path):
    """ 删除path目录下过去的文件，最多保留RESERVE_PACKAGE_NUM个
    """
    print("Remove outdate pkg file, path:%s" % path)
    files = os.listdir(path)
    files = []
    pkgs = []
    for f in files:
      if os.path.isdir(f): ##delete path in package path
        rm_file = os.path.join(path, f)
        print("[%s] is directory, remove it." % rm_file)
        shutil.rmtree(rm_file)
        continue
      statinfo=os.stat(os.path.join(path, f))
      pkgs.append(((int)(statinfo.st_ctime), f))
    pkgs.sort(lambda x,y:cmp(x[0],y[0]))
    while len(pkgs) > RESERVE_PACKAGE_NUM:
      print("Remove outdate pkg file, file:%s" % os.path.join(path, pkgs[0][1]))
      self._remove(os.path.join(path, pkgs[0][1]))
      del pkgs[0]

  #init the service path
  def init_service_env(self):
    """ 初始化服务的目录
    """
    # 初始化环境
    prepare_cmd = self.svr_script_ + " prepare " + self.svr_home_ + " " + self.svr_container_name_
    print("Prepare env, cmd:%s" % prepare_cmd)
    if not self._run_cmd(prepare_cmd):
      self.install_success_ = False
      self.install_errmsg_ = "Failed to prepare env, cmd:%s" % prepare_cmd
      return False
    # 使用root用户
    cur_user = getpass.getuser()
    print("Current user is:%s" % cur_user)
    if len(self.svr_user_) and cur_user <> self.svr_user_:
      print("Configurat user:%s, docker must use root." % (self.svr_user_,))

    print("Check service home:%s" % self.svr_home_)
    self._check_and_mk_missed_path(self.svr_home_)
    
    print("Check service env path:%s" % self.svr_history_env_path_)
    self._check_and_mk_missed_path(self.svr_history_env_path_)
        
    print("Check env conf path:%s" % self.svr_tmp_env_path_)
    self._check_and_mk_missed_path(self.svr_tmp_env_path_)
    print("Check service tmp path:%s" % self.svr_tmp_path_)
    self._check_and_mk_missed_path(self.svr_tmp_path_)
    self.clean_path(self.svr_tmp_path_)
    self.remove_outdate_pkg(self.svr_history_env_path_)
    return True
  #create version file to save version
  def save_version_file(self):
    """ 保存版本信息
    """
    print("Save version[image:%s, image_tag:%s, env:%s, env_md5:%s] to %s" % 
          (self.svr_image_file_,self.svr_image_tag_, self.svr_env_v_, self.svr_env_md5_, self.svr_version_file_))
    conf = "[version]\nimage=%s\nimage_tag=%s\nenv=%s\nenv_md5=%s\n" % (self.svr_image_file_,self.svr_image_tag_, self.svr_env_v_, self.svr_env_md5_)
    with open(self.svr_version_file_, 'w') as f:
      f.write(conf)

  def load_version_file(self):
    """ 加载版本信息
    """
    self.svr_online_image_file_ = ""
    self.svr_online_env_version_ = ""
    self.svr_online_image_tag_ = ""
    self.svr_online_env_md5_ = ""
    
    self.is_update_image_ = True    
    # 如果没有环境的版本号，则认为没有配置文件。
    self.is_update_env_ = len(self.svr_env_v_)>0
    print("Load version file:%s" % (self.svr_version_file_))
    if not os.path.isfile(self.svr_version_file_):
        print("Version file doesn't exist, file:%s" % self.svr_version_file_)
        return
    parser = ConfigParser.ConfigParser()
    try:
        parser.read(self.svr_version_file_)
        self.svr_online_env_version_ = parser.get("version", "env")
        self.svr_online_env_md5_ = parser.get("version", "env_md5")
        self.svr_online_image_tag_ = parser.get("version", "image_tag")
        self.svr_online_image_file_ = parser.get("version", "image")        
    except Exception, e:
        print("Failed to parse conf info file:%s, err:%s" % (self.svr_version_file_, e))
        return
    if self.svr_online_image_file_ == self.svr_image_file_ and  not self.is_svr_update_image_:
        self.is_update_image_ = False
    if self.svr_online_env_version_ == self.svr_env_v_ and self.svr_online_env_md5_ == self.svr_env_md5_ and not self.is_svr_update_env_:
        self.is_update_env_ = False
    self.is_update_env_ = False
    print("Image is changed:%s; env is changed:%s" % (self.is_update_iamge_, self.is_update_env_))

  #remove current version file
  def remove_version_file(self):
    """ 删除版本文件
    """
    print("Remove current verision file:%s" % self.svr_version_file_)
    self._remove(self.svr_version_file_)

  #out result to out_file
  def output_result(self):
    """ 输出执行结果信息
    """
    if self.install_success_:                  
      with open(self.svr_result_file_, 'w') as f:
        f.write("state=success\n")                 
        f.write("err=")                            
    else:                                      
      with open(self.svr_result_file_, 'w') as f:
        f.write("state=failure\n")                 
        f.write("err=%s" % self.install_errmsg_)   
     #download service image                   
  def download_image(self):
    """ 下载image
    """
    #lgoin
    #login_cmd = "docker login -u '%s' -p '%s' reg-test.lecloud.com" % (self.svr_reg_user_, self.svr_reg_passwd_)
    login_cmd = "docker login -u admin -p Harbor12345 reg-test.lecloud.com"
    if not self._run_cmd(login_cmd):
      self.install_errmsg_ = "Failure to login harbor, cmd:%s" % login_cmd
      self.install_success_ = False
      return False 
    # pull image      
    #pull_cmd = "docker pull %s/%s/%s:%s" % (self.svr_docker_harbor_ip_, self.svr_project_name_，self.svr_image_file_, self.svr_image_tag_) 
    pull_cmd = "docker pull reg-test.lecloud.com/test_service/app_svr_centos:7.2"
    print("pull image, cmd=%s" % (pull_cmd))
    if not self._run_cmd(pull_cmd):
      self.install_errmsg_ = "Failure to download image, cmd:%s" % pull_cmd
      self.install_success_ = False
      return False    
    return True
    
  #download service config
  def download_config(self):
    """ 下载配置的tar.gz
    """
    save_file = os.path.join(self.svr_history_env_path_, self.svr_env_pkg_file_)
    tmp_file = os.path.join(self.svr_tmp_path_, self.svr_env_pkg_file_)
    tmp_decrypt_file = os.path.join(self.svr_tmp_path_, "decrpyt_" + self.svr_env_pkg_file_)
    is_download = True
    if os.path.isfile(save_file):
      file_md5 = self._md5(save_file)
      if file_md5 <> self.svr_env_md5_:
        print("Backup file[%s]'s md5[%s] isn't same with specified md5[%s], remove it." % (save_file, file_md5, self.svr_env_md5_))
        self._remove(save_file)
      else:
        if not self.is_svr_update_env_:
          print("Package file:%s exist, doesn't download" % self.svr_env_pkg_file_)
          shutil.copyfile(save_file, tmp_file)
          is_download = False
        else:
          self._remove(save_file)
    if is_download:
      if os.path.isfile(tmp_file):
          self._remove(tmp_file)
      # save rsync passwd file
      if self.rsync_passwd_:
          cmd = "echo %s > %s" % (self.rsync_passwd_, self.rsync_passwd_file_)
          if not self._run_cmd(cmd):
              self.install_errmsg_ = "Failure to save rsync password file, cmd:%s" % cmd
              self.install_success_ = False
              return False
          cmd = "chmod 600 %s" % self.rsync_passwd_file_
          if not self._run_cmd(cmd):
              self.install_errmsg_ = "Failure to save rsync password file, cmd:%s" % cmd
              self.install_success_ = False
              return False
      rsync_cmd=""
      if self.rsync_passwd_:
          rsync_cmd = "rsync  -vzrtopg --progress --password-file=%s  %s@%s::%s %s" % (self.rsync_passwd_file_, self.rsync_user_, self.svr_repo_, self.svr_env_pkg_pathfile_, tmp_file)
      else:
          rsync_cmd = "rsync  -vzrtopg --progress %s::%s %s" % (self.svr_repo_, self.svr_env_pkg_pathfile_, tmp_file)
      print("rsync env conf, cmd=%s" % rsync_cmd)
      if not self._run_cmd(rsync_cmd):
        self.install_errmsg_ = "Failure to download package, cmd:%s" % rsync_cmd
        self.install_success_ = False
        return False
      #check md5
      file_md5 = self._md5(tmp_file)
      if file_md5 <> self.svr_env_md5_:
        self.install_errmsg_ = "File[%s]'s md5[%s] isn't same with specified md5[%s]" % (self.svr_env_pkg_file_, file_md5, self.svr_env_md5_)
        self.install_success_ = False
        print(self.install_errmsg_)
        return False
      #backup
      shutil.copy(tmp_file, save_file)

    if len(self.svr_env_passwd_):
      #decrpty
      cmd = "openssl des3 -d -k %s -salt -in %s > %s" % (self.svr_env_passwd_, tmp_file, tmp_decrypt_file)
      print("decrypt tar.gz, cmd:%s" % cmd)
      if not self._run_cmd(cmd):
        self.install_errmsg_ = "Failure to decrpty package, cmd:%s" % cmd
        self.install_success_ = False
        return False
    else:
      shutil.copy(tmp_file, tmp_decrypt_file)
    remove_cmd = "rm -f %s" % tmp_file
    if not self._run_cmd(remove_cmd):
      self.install_errmsg_ = "Failure to remove tmp package:%s" % tmp_file
      self.install_success_ = False
      return False
    if os.path.isdir(self.svr_tmp_env_path_):
      self._remove(self.svr_tmp_env_path_)
    os.mkdir(self.svr_tmp_env_path_)
    unzip_cmd = "tar -zxvf " + tmp_decrypt_file + " -C " + self.svr_tmp_env_path_ + " >/dev/null"
    print("untar tar.gz, cmd:%s" % unzip_cmd)
    if not self._run_cmd(unzip_cmd):
      self.install_errmsg_ = "Failure to unpack env package:%s" % tmp_file
      self.install_success_ = False
      return False
    self._remove(tmp_decrypt_file)
    return True

  #start service
  def start_service(self):
    """ 启动服务
    """
    start_cmd = self.svr_script_ + " start " + self.svr_home_ + " " + self.svr_container_name_
    if not self._run_cmd(start_cmd):
      self.install_success_ = False
      self.install_errmsg_ = "Failed to start service, cmd:%s" % start_cmd
      return False
    return True

  #stop service
  def stop_service(self):
    """ 停止服务
    """
    stop_cmd = self.svr_script_ + " stop " + self.svr_home_ + " " + self.svr_container_name_
    if not self._run_cmd(stop_cmd):
      self.install_success_ = False
      self.install_errmsg_ = "Failed to stop service, cmd:%s" % stop_cmd
      return False
    return True

  #check service
  def check_service(self):
    """ check服务
    """
    check_cmd = self.svr_script_ + " check " + self.svr_home_ + " " + self.svr_container_name_
    if not self._run_cmd(check_cmd):
      self.install_success_ = False
      self.install_errmsg_ = "Failed to check service, cmd:%s" % check_cmd
      return False
    return True

  #install service
  def install_service(self):
    """ 安装服务
    """
    install_cmd = ""
    if self.is_update_env_:
      install_cmd = self.svr_script_ + " install "  + self.svr_home_ + self.svr_tmp_env_path_
    else:
      self.install_success_ = False
      self.install_errmsg_ = "Inner error, none is needed to be updated."
      return False
    if not self._run_cmd(install_cmd):
      self.install_success_ = False
      self.install_errmsg_ = "Failed to install service, cmd:%s" % install_cmd
      return False
    return True
  

  def _md5(self, file):
    """  pkg file's md5
    """
    md5_obj = hashlib.md5()
    with open(file, "rb") as f:
        while True:
            d = f.read(8096)
            if not d: break
            md5_obj.update(d)
    return md5_obj.hexdigest().lower()

  #remove file or dir
  def _remove(self, df):
    """ 删除文件或目录
    """
    if os.path.isfile(df):
      os.remove(df)
    elif os.path.isdir(df):
      shutil.rmtree(df)

  #check and create missing subpath
  def _check_and_mk_missed_path(self, path):
    """ 创建缺省的目录
    """
    if not os.path.isdir(path):
      os.makedirs(path)

  #runing system cmd
  def _run_cmd(self, cmd):
    """ 执行system 命令
    """
    print "run cmd:%s" % cmd
    ret = os.system(cmd)
    ret >>= 8
    return ret == 0

def main():
  """ 运行main函数
  """  
  install = DcmdInstall()
  #1.check version
  try:
    print("\n%s:STEP 0: init svr enviroment.......\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    if not install.init_service_env():
      install.output_result()
      return

    #print("\n%s:STEP 1: Check version.............\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    #install.load_version_file()
    #if not install.is_update_env_:
    #  print "==>The package version and env-version to be installed is same as current version, install succeed."
    #  install.install_success_ = True
    #  install.output_result()
    #  return
    
    print("\n%s:STEP 2: Download image............\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    if install.is_update_image_:
      if not install.download_image():
        install.output_result()
        return
    else:
      print("\n%s:Not update package.\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
      
    print("\n%s:STEP 3: Download config file.........\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    if install.is_update_env_:
      if not install.download_config():
        install.output_result()
        return
    else:
      print("\n%s:Not update env-version.\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    
    print("\n%s:STEP 4: Stop current service........\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    if not install.stop_service():
      install.output_result()
      return
    
    print("\n%s:STEP 5: Remove version file............\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    install.remove_version_file()
    
    print("\n%s:STEP 6: Install service..............\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    if not install.install_service():
      install.output_result()
      return
    
    print("\n%s:STEP 7: Start service...............\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    if not install.start_service():
      install.output_result()
      return
    
    print("\n%s:STEP 8: Create service version file............\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    install.save_version_file()
    
    print("\n%s:STEP 9: Check service............\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    if not install.check_service():
      install.output_result()
      return
    
    print("%s:Success to install serivice.\n" % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    install.install_success_ = True
  except Exception, e:
    print ("%s:Failed to install, Exception:%s" % (datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), e))
    traceback.print_exc()
    install.install_errmsg_ = "Failed to install for exception: %s" % e
    install.install_success_ = False
 
  install.output_result()
  
  
if __name__ == "__main__":
  main()