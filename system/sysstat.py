#!/usr/bin/env python

# name: system stats
# desc: CPU,mem,disk,network stats for linux
# lang: python

import os
import time
import subprocess
from subprocess import Popen, PIPE
from multiprocessing.pool import ThreadPool


def file_desc():
    f = open('/proc/sys/fs/file-nr')
    line = f.readline()
    
    fd = [int(x) for x in line.split()]
    
    return fd

def load_avg():
    f = open('/proc/loadavg')
    line = f.readline()
    f.close()
    
    load_avgs = [float(x) for x in line.split()[:3]]
    
    return load_avgs

def cpu_stats(sample_duration=2):
    f1 = open('/proc/stat')
    f2 = open('/proc/stat')
    c1 = f1.read()
    time.sleep(sample_duration)
    c2 = f2.read()
    f1.close()
    f2.close()

    cs1 = {}
    for l in c1.splitlines():
        if 'cpu' not in l:
            continue
        d = l.strip().split()
        cs1[d[0]] = d[1:]

    cs2 = {}
    for l in c2.splitlines():
        if 'cpu' not in l:
            continue
        d = l.strip().split()
        cs2[d[0]] = d[1:]

    cs = {}
    for c in cs1.keys():
        deltas = [int(b) - int(a) for a, b in zip(cs1[c], cs2[c])]
        total = sum(deltas)
        percents = [100 - (100 * (float(total - x) / total)) for x in deltas ]
        cs[c] = {
            'user': percents[0],
            'nice': percents[1],
            'system': percents[2],
            'idle': percents[3],
            'iowait': percents[4],
            'irq': percents[5],
            'softirq': percents[6],
        }

    return cs


def disk_usage():
    """Return disk usage statistics."""
    df = {}
    output = Popen(['df', '-l', '-m', '-x', 'proc', '-x', 'tmpfs', '-x', 'devtmpfs', \
             '-x', 'ecryptfs'], stdout=PIPE, universal_newlines=True).communicate()[0]

    lines = output.splitlines()[1:]
    count = 0
    while ( count < len(lines) ):
        d = lines[count].split()
        if len(d) == 1:
            count = count + 1
            d = d + lines[count].split()

        df[d[0]] = d[1:]

        count = count + 1

    return df


def disk_stats(sample_duration=2):
    """Return (inbytes, outbytes, in_num, out_num, ioms) of disk."""
    f1 = open('/proc/diskstats')
    f2 = open('/proc/diskstats')
    content1 = f1.read()
    time.sleep(sample_duration)
    content2 = f2.read()
    f1.close()
    f2.close()

    ds1 = {}
    for l in content1.splitlines():
        d = l.strip().split()
        if d[2].startswith('loop') or d[2].startswith('ram') or \
           d[2].startswith('fd') or d[2].startswith('sr'):
           continue
        ds1[d[2]] = [d[3], d[7], d[4], d[8], d[12]]

    ds2 = {}
    for l in content2.splitlines():
        d = l.strip().split()
        if d[2].startswith('loop') or d[2].startswith('ram') or \
           d[2].startswith('fd') or d[2].startswith('sr'):
           continue
        ds2[d[2]] = [d[3], d[7], d[4], d[8], d[12]]

    ds = {}
    for d in ds1.keys():
        rnum = float(int(ds2[d][0]) - int(ds1[d][0])) / sample_duration
        wnum = float(int(ds2[d][1]) - int(ds1[d][1])) / sample_duration
        rKB = float(int(ds2[d][2]) - int(ds1[d][2])) / sample_duration / 1024
        wKB = float(int(ds2[d][3]) - int(ds1[d][3])) / sample_duration / 1024
        util = 100 * (float(int(ds2[d][4]) - int(ds1[d][4]))/(sample_duration * 1000))
        ds[d] = [rKB, wKB, rnum, wnum, util]

    return ds


class DiskError(Exception):
    pass


def mem_stats():
    f = open('/proc/meminfo')
    for line in f:
        if line.startswith('MemTotal:'):
            mem_total = int(line.split()[1]) * 1024
        elif line.startswith('Active: '):
            mem_active = int(line.split()[1]) * 1024
        elif line.startswith('MemFree:'):
            mem_free = (int(line.split()[1]) * 1024)
        elif line.startswith('Cached:'):
            mem_cached = (int(line.split()[1]) * 1024)
        elif line.startswith('SwapTotal: '):
            swap_total = (int(line.split()[1]) * 1024)
        elif line.startswith('SwapFree: '):
            swap_free = (int(line.split()[1]) * 1024)

    f.close()

    return (mem_active, mem_total, mem_cached, mem_free, swap_total, swap_free)


# net rx/tx stat
def net_stats(sample_duration=2):
    f1 = open('/proc/net/dev')
    f2 = open('/proc/net/dev')
    content1 = f1.read()
    time.sleep(sample_duration)
    content2 = f2.read()
    f1.close()
    f2.close()

    sep = ':'
    stats1 = {}
    for line in content1.splitlines():
        if sep in line:
            i = line.split(':')[0].strip()
            data = line.split(':')[1].split()
            rx_bytes1, tx_bytes1 = (int(data[0]), int(data[8]))
            rx_pack1, tx_pack1 = (int(data[1]), int(data[9]))
            stats1[i] = [rx_bytes1, tx_bytes1, rx_pack1, tx_pack1]

    stats2 = {}
    for line in content2.splitlines():
        if sep in line:
            i = line.split(':')[0].strip()
            data = line.split(':')[1].split()
            rx_bytes2, tx_bytes2 = (int(data[0]), int(data[8]))
            rx_pack2, tx_pack2 = (int(data[1]), int(data[9]))
            stats2[i] = [rx_bytes2, tx_bytes2, rx_pack2, tx_pack2]

    stats_ps = {}
    for i in stats1.keys():
        rx_bytes_ps = (stats2[i][0] - stats1[i][0]) / sample_duration
        tx_bytes_ps = (stats2[i][1] - stats1[i][1]) / sample_duration
        rx_pps = (stats2[i][2] - stats1[i][2]) / sample_duration
        tx_pps = (stats2[i][3] - stats1[i][3]) / sample_duration
        stats_ps[i] = [ rx_bytes_ps, tx_bytes_ps, rx_pps, tx_pps ]

    return stats_ps
    
class NetError(Exception):
    pass


def main():
    pool = ThreadPool(processes=3)
    cp = pool.apply_async(cpu_stats)
    dp = pool.apply_async(disk_stats)
    np = pool.apply_async(net_stats)

    cs = cp.get()
    ds = dp.get()
    nss = np.get()

    # load
    print('load: %s' % load_avg()[0])
    
    # cpu
    print("\ncpu stats:\n%14s %8s %8s %8s %8s %8s %8s %8s" % ("device", "user", "nice", "system", "iowait", "irq", "softirq", "idle"))
    #cs = cpu_stats()
    cpus = list(cs.keys())
    cpus.sort()
    for c in cpus:
      print("%14s %7.1f%% %7.1f%% %7.1f%% %7.1f%% %7.1f%% %7.1f%% %7.1f%%" % (c, cs[c]['user'], \
          cs[c]['nice'], cs[c]['system'], cs[c]['iowait'], cs[c]['irq'], cs[c]['softirq'], cs[c]['idle']))

    # disk
    print('\ndisk usage:\n%14s %9s %8s %8s %8s %s' % ("device", "total(MB)", "used(MB)", "free(MB)", "used%", "mount point"))
    df = disk_usage()
    disks = list(df.keys())
    disks.sort()
    for d in disks:
      print('%14s %9s %8s %8s %8s %s' % (d, df[d][0], df[d][1], df[d][2], df[d][3], df[d][4]))

    print("\ndisk stats:\n%14s %8s %8s %8s %8s %8s" % ("device", "rKB/s", "wKB/s", "r/s", "w/s", "util%"))
    #ds = disk_stats()
    devices = list(ds.keys())
    devices.sort()
    for d in devices:
      print("%14s %8.1f %8.1f %8.1f %8.1f %7s%%" % (d, ds[d][0], ds[d][1], ds[d][2], ds[d][3], ds[d][4]))
      
    # memory
    print("\nmem stats:\n%14s %8s %8s %8s %8s" % ("total(MB)", "used(MB)", "cached(MB)", "free(MB)", "usage%"))
    used, total, cached, free, _, _ = mem_stats()
    mem_usage = float(used) * 100 / float(total)
    print("%14d %8d %10d %8d %7.2f%%" % (int(total)/1048576, int(used)/1048576, \
      int(cached)/1048576, int(free)/1048576, mem_usage))

    # network
    print("\nnetwork stats:\n%14s %10s %10s %8s %8s" % ("interface", "rbyte/s", "tbyte/s", "rpps", "tpps"))
    #nss = net_stats()
    interfaces = list(nss.keys())
    interfaces.sort()
    for i in interfaces:
      print("%14s %10d %10d %8d %8d" % (i, nss[i][0], nss[i][1], nss[i][2], nss[i][3]))
    
    
if __name__ == '__main__':   
    main()

