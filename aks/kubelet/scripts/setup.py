import os, sys, subprocess, shutil
import re, collections
import logging

# Setup Logging
LOG_FORMAT = '%(asctime)s %(levelname)s(%(name)s) - %(message)s'
LOG_LEVEL = logging.DEBUG if 'DEBUG' in os.environ else logging.INFO
logging.basicConfig(format=LOG_FORMAT, level=LOG_LEVEL)
log = logging

# String Parser
pattern_env = re.compile('^([^=]*)=(.*)$')  # (key)=(value...)
pattern_ops = re.compile('\s+')             # (arg1) (arg2) ...
def parseProp(line): return pattern_env.split(line.strip())[1:-1]
def parseOps(line):  return pattern_ops.split(line.strip())
def parseArg(lst):   return collections.OrderedDict([_.split('=', 1) for _ in lst])
def joinDict(dic, delimiter=' '): return delimiter.join('{}={}'.format(k, v) for k, v in dic.items())

# Process Each Env Line
def parseEnv(line):
  name, ops = parseProp(line)

  log.info("parsing '{}'".format(name))
  ops = parseOps(ops)
  args = parseArg(ops)

  # Check Option
  key = '--authentication-token-webhook'
  new, old = 'true', args.get(key, None)

  if new != old:
    log.info("Update '{}' ({} -> {})".format(key, old, new))
    args[key] = new
    line = name + '=' + joinDict(args)
    return (line, True)
  else:
    log.info("Skip '{}={}'".format(key, old))
    return (line, False)

def getOrDefault(arr, i, default): return (arr + [None] * i)[i] or default
def readLines(filename):
  with open(filename) as f:
    return [line.strip() for line in f.readlines()]
def backup(source, target):
  log.info("copy file ({} -> {})".format(source, target))
  shutil.copy(source, target)

# Entrypoint
def main():
  log.info('{1} ({3})'.format(*os.uname()))

  # Load Config File
  config_file = getOrDefault(sys.argv, 1, '/etc/default/kubelet')

  log.info("loading '{}'".format(config_file))
  lines = readLines(config_file)

  # Find KUBELET_CONFIG
  KUBELET_CONFIG = next( (_ for _ in lines if _.startswith('KUBELET_CONFIG')), None )
  if not KUBELET_CONFIG:
    log.warn("No 'KUBELET_CONFIG' in '{}'".format(config_file))
    log.debug("loaded config file contents\n{}".format('\n'.join(lines)))
    return
  
  # Set '--authentication-token-webhook=true'
  updated_line, changed = parseEnv(KUBELET_CONFIG)

  if changed:
    lines[lines.index(KUBELET_CONFIG)] = updated_line

    # copy backup files
    backup(config_file, config_file + '.org')
    backup(config_file, config_file + '.bak')

    # overwrite current file
    log.info("updated content of '{}'".format(config_file))
    log.info('\n' + '\n'.join(lines))
    # with open(config_file, 'w') as f:
    #   log.info("overwrite '{}' file".format(f.name))
    #   f.write('\n'.join(lines))

    # Restart Kubelet
    try:
      cmd = 'systemctl status kubelet'
      log.info("execute '{}'".format(cmd))
      stdout = subprocess.check_output(cmd, shell=True)
      # for l in stdout.split('\n'): log.info('  ' + l)
      log.info('\n' + stdout)
    except:
      pass

if __name__ == '__main__':
  try:
    main()
  except Exception as e:
    _, _, tb = sys.exc_info()
    # log.error("{} (lines: {}, file: '{}')".format(e, tb.tb_lineno, tb.tb_frame.f_code.co_filename))
    log.error("{}".format(e))
    sys.exit(1)
