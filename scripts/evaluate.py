#!/usr/bin/python3


## ../../bin/evaluate.py $(find ../../data/checkpoints/BUSCO_results/ -name "full_table*")

import sys
import argparse

parser = argparse.ArgumentParser(description='Pre-filter BUSCO sets for phylogenomic analyses')
parser.add_argument('-i', '--in_list', action='store', type=str, required=True,
                    help='path to text file containing the list of ingroup taxa')
parser.add_argument('--max_mis_in', metavar="INT", action='store', type=int, default=0,
        help='maximum number of samples without data in the ingroup, default: 0, i.e. all samples have data')
parser.add_argument('-o', '--out_list', action='store', type=str, required=True,
                    help='path to text file containing the list of outgroup taxa')
parser.add_argument('--max_mis_out', metavar='INT', action='store', type=int, default=0,
        help='maximum number of samples without data in the outgroup, default: 0, i.e. all samples have data')
parser.add_argument('--max_avg', metavar='INT', action='store', type=int, default=1,
        help='maximum average number of paralog')
parser.add_argument('--max_med', metavar='INT', action='store', type=int, default=1,
        help='maximum median number of paralogs')
parser.add_argument('-f', '--files', metavar='TABLES', nargs='+', required=True,
                    help='full BUSCO results tables that should be evaluated (space delimited), e.g. -f table1 table2 table3')
parser.add_argument('-B', '--BUSCOs', metavar='IDs', nargs='*', default = [],
        help='list of BUSCO IDs to be evaluated, default, if not set: all, or e.g. -B EOG090X0IQO EOG090X0GLS')
parser.add_argument('--outfile', metavar='FILE', action='store', type=str,
                    help='name of outputfile to write results to')

args = parser.parse_args()
maxavg = args.max_avg
maxmed = args.max_med
maxmisin = args.max_mis_in
maxmisout = args.max_mis_out
passcount=0

files = args.files #sys.argv[1:]
ingroup = [ l.strip() for l in open(args.in_list)]
outgroup = [ l.strip() for l in open(args.out_list)]
data = {}
lines = []

lines.append("# Ingroup taxa: %s" %ingroup)
lines.append("# Outgroup taxa %s" %outgroup)
lines.append("# tables included: %s" %files)
lines.append("# maximum number of ingroup samples with missing data: %i" %maxmisin)
lines.append("# maximum number of outgroup samples with missing data: %i" %maxmisout)
lines.append("# maximum average number of paralogs: %s" %maxavg)
lines.append("# maximum median number of paralogs: %s" %maxmed)
lines.append("#")
for l in lines:
    print(l)

for f in files:
    group = ""
    taxon = ""
    for e in f.split("/"):
        if e in ingroup:
            group = "ingroup"
            break
        elif e in outgroup:
            group = "outgroup"
            break

    if not group:
        lines.append("# Can't assign the file %s to in or outgroup" %f)
        print(lines[-1])
    else:
        taxon = e
        lines.append('# found BUSCO table for taxon %s -> %s' %(e, group))
        print(lines[-1])

    linecount = 0
    for line in open(f):
        if not line.startswith("#") and not ('Missing' in line.split() or "Fragmented" in line.split()):
#            linecount+=1
#            print(linecount,line.split()[0:2],group)
            ID = line.split()[0]
            if len(args.BUSCOs) > 0:
                if not ID in args.BUSCOs:
#                    lines.append("%s\tnot on list" %ID)
#                    print(lines[-1])
                    continue
	    #if the ID is encountert for the first time
            if not ID in data:
                data[ID] = {group: {f: int(1)}}
            else:
	    	#if the ID was encountert before but not for this group
                if not group in data[ID]:
                    data[ID][group] = {f: int(1)}
                else:
	    	    #if the ID was encountert before for this group but not in this file         
                    if not f in data[ID][group]:
                        data[ID][group][f] = int(1)
                    else:
                        data[ID][group][f]+=1

#            print(data)

lines.append("## BUSCO ID\tn ingroup\tn outgroup\tparalog counts(sorted)\tavg. paralogs\tmedian paralogs")
if not args.outfile:
    print(lines[-1])
for B in data.keys():
    outgroupcount = 0
    ingroupcount = 0
    average = 0
    median = 0
    paracounts = []
    if 'outgroup' in data[B]:
        outgroupcount = len(data[B]['outgroup'])
    else:
        data[B]['outgroup'] = {}
    if 'ingroup' in data[B]:
        ingroupcount = len(data[B]['ingroup'])
    else:
        data[B]['ingroup'] = {}
    for group in ['ingroup','outgroup']:
        for s in data[B][group]:
            paracounts.append(data[B][group][s])

    if not paracounts:
        paracounts.append(0)
    if len(paracounts) % 2:
        med = sorted(paracounts)[int(len(paracounts)/2)]
    else:
        med = (sorted(paracounts)[int(len(paracounts)/2)] + sorted(paracounts)[int(len(paracounts)/2)-1]) / 2
    line = "%s\t%i\t%i\t%s\t%f\t%f" %(B, ingroupcount, outgroupcount, sorted(paracounts), sum(paracounts)/len(paracounts), med)
    if (len(ingroup) - ingroupcount) > maxmisin or (len(outgroup) - outgroupcount) > maxmisout:
        line+="\tfail (count)"
    else:
        if (sum(paracounts)/len(paracounts) <= maxavg) and med <= maxmed:
            line+="\tpass"
            passcount+=1
        else:
            line+="\tfail"
            if (sum(paracounts)/len(paracounts) > maxavg):
                line+=" (average)"
            
            if (med > maxmed):
                line+=" (median)"
    if args.outfile:
        lines.append(line)
    else:
        print(line)

if len(data) > 0:
    lines.append("# Evaluated %i BUSCOs - %i (%s %%) passed" %(len(data), passcount, '{0:.2f}'.format(passcount/len(data)*100)))
else:
    lines.append("# No BUSCO evaluated - incorrect filter '-B' ?")

if args.outfile:
    fh = open(args.outfile, 'w')
    for l in lines:
        fh.write(l+"\n")
else:
    for l in lines:
        if not l.startswith("#"):
            print(l)
print(lines[-1]+"\n")
