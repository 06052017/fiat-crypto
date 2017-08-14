#!/usr/bin/env python
from __future__ import with_statement
from memoize import memoize
import codecs, re, sys
import random

LAMBDA = u'\u03bb'

OP_NAMES = {'*':'MUL', '+':'ADD', '>>':'SHL', '<<':'SHR', '|':'OR', '&':'AND'}

MAX_INSTRUCTION_WINDOW = 1000

INSTRUCTIONS_PER_CYCLE = 4

REGISTERS = tuple(['RAX', 'RBX', 'RCX', 'RDX', 'RSI', 'RDI', 'RBP', 'RSP']
                  + ['r%d' % i for i in range(8, 16)])

CORE_DATA = tuple(('p%d' % i, 1) for i in range(8))
CORES = tuple(name for name, count in CORE_DATA)
CORE_COUNT = dict(CORE_DATA)

def possible_cores_for_line(line, var_types):
    # from page 233 of http://agner.org/optimize/instruction_tables.pdf
    if line['op'] == '*':
        if line['type'] == 'uint64_t' and '0x13' in line['args']: # * 19 can be either imul r64/r64/i, or two lea; we skip the second case because jgross can't figure out what cost to use for it
            return ({
                'core': ({ 'name' : 'p1' , 'latency' : 1 },),
                'latency' : 3,
                'instruction' : 'IMUL r64,r64,i'
                },)
        elif line['type'] == 'uint128_t' and all(var_types[var] == 'uint64_t' for var in line['args']): # mulx
            return ({
                'core': tuple({ 'name' : core_name , 'latency' : 1 } for core_name in ('p1', 'p5')),
                'latency' : 4,
                'instruction' : 'MULX r64,r64,r64'
                },)
        else:
            assert False
    elif line['op'] == '+':
        if line['type'] == 'uint128_t':
            return tuple({
                'core' : ({ 'name' : core_name , 'latency' : 1+1 },),
                'latency' : 1+1,
                'instruction' : 'ADD; ADC(X)'
                } for core_name in ('p0', 'p6'))
        elif line['type'] == 'uint64_t':
            return tuple({
                'core' : ({ 'name' : core_name , 'latency' : 1 },),
                'latency' : 1,
                'instruction' : 'ADD'
                } for core_name in ('p0', 'p1', 'p5', 'p6'))
        else:
            assert False
    elif line['op'] in ('>>', '<<'):
        if var_types[line['args'][0]] == 'uint128_t' and line['type'] == 'uint64_t' and line['args'][1][:2] == '0x':
            return tuple({
                'core' : ({ 'name' : core_name , 'latency' : 1 },),
                'latency' : 3,
                'instruction' : ('SHLD' if line['op'] == '<<' else 'SHRD') + ' r,r,i'
                } for core_name in ('p1',))
        elif var_types[line['args'][0]] == 'uint64_t' and line['type'] == 'uint64_t' and line['args'][1][:2] == '0x':
            return tuple({
                'core' : ({ 'name' : core_name , 'latency' : 1 },),
                'latency' : 1,
                'instruction' : ('SHL' if line['op'] == '<<' else 'SHR') + ' r,i'
                } for core_name in ('p0', 'p6'))
        else:
            assert False
    elif line['op'] in ('&', '|', '^'):
        return tuple({
            'core' : ({ 'name' : core_name , 'latency' : 1 },),
            'latency' : 1,
            'instruction' : {'&':'AND', '|':'OR', '^':'XOR'}[line['op']]
            } for core_name in ('p0', 'p1', 'p5', 'p6'))
    elif line['op'] in ('LOAD',):
        if line['type'] == 'uint128_t': # issue 2 MOV, same port, block on p4
            return tuple({
                'core' : ({ 'name' : core_name , 'latency' : 2 }, { 'name' : 'p4' , 'latency' : 2 }),
                'latency' : 2,
                'instruction' : 'MOV m,r; MOV m,r'
                } for core_name in ('p2', 'p3', 'p7'))
        elif line['type'] == 'uint64_t':
            return tuple({
                'core' : ({ 'name' : core_name , 'latency' : 1 }, { 'name' : 'p4' , 'latency' : 1 }),
                'latency' : 1,
                'instruction' : 'MOV m,r'
                } for core_name in ('p2', 'p3', 'p7'))
        else:
            assert False
    elif line['op'] in ('STORE',):
        if line['type'] == 'uint128_t': # issue 2 MOV, different ports
            return ({
                'core' : tuple({ 'name' : core_name , 'latency' : 1 } for core_name in ('p2', 'p3')),
                'latency' : 1,
                'instruction' : 'MOV r64,m; MOV r64,m'
                },)
        elif line['type'] == 'uint64_t':
            return tuple({
                'core' : ({ 'name' : core_name , 'latency' : 1 },),
                'latency' : 1,
                'instruction' : 'MOV r64,m'
                } for core_name in ('p2', 'p3'))
        else:
            assert False
    else:
        assert False



if len(sys.argv) > 1:
    MAX_INSTRUCTION_WINDOW = int(sys.argv[1])

def get_lines(filename):
    with codecs.open(filename, 'r', encoding='utf8') as f:
        lines = f.read().replace('\r\n', '\n')
    return [line.strip() for line in re.findall("%s '.*?[Rr]eturn [^\r\n]*" % LAMBDA, lines, flags=re.DOTALL)[0].split('\n')]

def strip_casts(text):
    return re.sub(r'\(u?int[0-9]*_t\)\s*\(?([^\)]*)\)?', r'\1', text)

def get_input_var_names(input_data):
    return tuple(i for i in input_data['vars'].replace('%core', '').replace(',', ' ').replace('(', ' ').replace(')', ' ').replace("'", ' ').split(' ')
                 if i != '')

def parse_lines(lines):
    orig_lines = list(lines)
    lines = list(map(strip_casts, orig_lines))
    assert lines[0][:len(LAMBDA + ' ')] == LAMBDA + ' '
    assert lines[0][-1] == ','
    ret = {}
    ret['vars'] = lines[0][len(LAMBDA + ' '):-1]
    assert lines[-1][-1] == ')'
    ret['return'] = lines[-1][:-1].replace('return ', '').replace('Return ', '')
    ret['header'] = orig_lines[0]
    ret['footer'] = orig_lines[-1]
    ret['lines'] = []
    var_types = dict((var, 'uint64_t') for var in get_input_var_names(ret))
    for line, orig_line in zip(lines, orig_lines)[1:-1]:
        datatype, varname, arg1, op, arg2 = re.findall('^(u?int[0-9]*_t) ([^ ]*) = ([^ ]*) ([^ ]*) ([^ ]*);(?: // .*)?$', line)[0]
        var_types[varname] = datatype
        cur_line = {'type':datatype, 'out':varname, 'op':op, 'args':(arg1, arg2), 'source':orig_line}
        possible_cores = possible_cores_for_line(cur_line, var_types)
        cur_line['cores'] = possible_cores
        ret['lines'].append(cur_line)
    print('Compiling %d lines in groups of %d...' % (len(ret['lines']), min(MAX_INSTRUCTION_WINDOW, len(ret['lines']))))
    ret['lines'] = tuple(ret['lines'])
    split_ret = []
    for start in range(0, len(ret['lines']), MAX_INSTRUCTION_WINDOW):
        cur_ret = dict(ret)
        cur_ret['lines'] = ret['lines'][start:][:MAX_INSTRUCTION_WINDOW]
        split_ret.append(cur_ret)
    return tuple(split_ret)

def get_var_names(input_data):
    return tuple(line['out'] for line in input_data['lines'])

def get_output_var_names(input_data):
    return tuple(i for i in data['return'].replace(',', ' ').replace('(', ' ').replace(')', ' ').split(' ')
                 if i != '')

def create_set(name, items):
    ret = ''
    ret += 'set of int: %s = 1..%d;\n' % (name, len(items))
    for i, item in enumerate(items):
        ret += '%s: %s = %d; ' % (name, item, i+1)
    ret += 'array[%s] of string: %s_NAMES = ["' % (name, name)
    ret += '", "'.join(items) + '"];\n'
    ret += '\n'
    return ret

def schedule(data, basepoint, do_print):
    def make_data_dependencies(input_data):
        input_var_names = get_input_var_names(input_data)
        dependencies = dict((var, tuple()) for var in input_var_names)
        for line in input_data['lines']:
            dependencies[line['out']] = tuple(arg for arg in line['args']
                                              if arg[0] not in '0123456789')
        return dependencies

    def make_reverse_data_dependencies(dependencies):
        reverse_dependencies = {}
        for k, v in dependencies.items():
            for arg in v:
                if arg not in reverse_dependencies.keys(): reverse_dependencies[arg] = []
                reverse_dependencies[arg].append(k)
        return reverse_dependencies

    def get_possible_next_statements(remaining_vars, dependencies):
        return [var for var in remaining_vars
                if all(arg not in remaining_vars for arg in dependencies[var])]

    def make_initial_core_state():
        return {'cores':dict((name, [0] * count) for name, count in CORE_DATA),
                'registers':dict((name, None) for name in REGISTERS)}

#    def freeze_core_state(core_state):
#        return (tuple(tuple(core_state['cores'][name]) for name in CORES),
#                tuple(core_state['registers'][name] for name in REGISTERS))
#    def unfreeze_core_state(core_state):
#        return {'cores':dict((name, list(cycles_until_free)) for name, cycles_until_free in zip(CORES, core_state[0])),
#                'registers':dict((name, var) for name, var in zip(REGISTERS, core_state[1]))}

    def get_initial_indices(input_data):
        #if basepoint == 0:
        #    return tuple(list(get_input_var_names(input_data)) + list(get_var_names(input_data)))
        #else:
        return tuple(get_var_names(input_data))



#    def make_source(input_data, var):
#        input_var_names = get_input_var_names(input_data)
#        if var in input_var_names: return 'LOAD %s' % var

#    def freeze_core_state(vars_ready_at, core_remaining_cycle_count,



    dependencies = make_data_dependencies(data)
    reverse_dependencies = make_reverse_data_dependencies(dependencies)

    def make_initial_core_state():
        vars_remaining_cycles = {}
        core_remaining_cycle_count = dict([(core_name, [0] * core_count) for core_name, core_count in CORE_DATA]
                                          + [(core_name, [0]) for core_name in REGISTERS])
        cur_instructions_in_cycle = 0
        register_vals = dict((var, None) for var in REGISTERS)
        return vars_remaining_cycles, core_remaining_cycle_count, cur_instructions_in_cycle, register_vals

    def freeze_gen(v, rec=(lambda x:x)):
        if isinstance(v, list):
            return ('list', tuple(map(rec, v)))
        if isinstance(v, tuple):
            return ('tuple', tuple(map(rec, v)))
        elif isinstance(v, dict):
            return ('dict', tuple(sorted((k, rec(val)) for k, val in v.items())))
        else:
            return v
    def unfreeze_gen(v, rec=(lambda x:x)):
        if isinstance(v, tuple):
            ty, v = v
            if ty == 'list':
                return list(map(rec, v))
            elif ty == 'tuple':
                return tuple(map(rec, v))
            elif ty == 'dict':
                return dict((k, rec(val)) for k, val in v)
            else:
                print('Freeze error: %s' % repr((ty, v)))
                assert False
        else:
            return v
    def freeze(v):
        return freeze_gen(v, freeze)
    def unfreeze(v):
        return unfreeze_gen(v, unfreeze)

    def update_register_vals_with_core_args(core, args, register_vals):
        new_rdx = register_vals['RDX']
        if 'MULX' in core['instruction']:
            new_rdx = sorted(args, key=(lambda x: int(x.lstrip('0x'))))[0]
        changed = (register_vals['RDX'] != new_rdx)
        register_vals['RDX'] = new_rdx
        return changed, register_vals

    @memoize
    def update_core_state(var, core, args, core_state):
        core = unfreeze(core)
        (vars_remaining_cycles, core_remaining_cycle_count, cur_instructions_in_cycle, register_vals) = unfreeze(core_state)
        changed, register_vals = update_register_vals_with_core_args(core, args, register_vals)
        cost = 0
        if cur_instructions_in_cycle >= INSTRUCTIONS_PER_CYCLE:
            cost += 1
            cur_instructions_in_cycle = 0
            for c in core_remaining_cycle_count.keys():
                for i in range(len(core_remaining_cycle_count[c])):
                    core_remaining_cycle_count[c][i] = max(0, core_remaining_cycle_count[c][i] - 1)
            vars_remaining_cycles = dict((var, c - 1) for var, c in vars_remaining_cycles.items()
                                         if c > 1)
        cycles_passed = max([min(core_remaining_cycle_count[port['name']]) for port in core['core']] +
                            [vars_remaining_cycles[v] for v in dependencies[var] if v in vars_remaining_cycles.keys()])
        if cycles_passed != 0:
            cost += cycles_passed
            cur_instructions_in_cycle = 1
            for c in core_remaining_cycle_count.keys():
                for i in range(len(core_remaining_cycle_count[c])):
                    core_remaining_cycle_count[c][i] = max(0, core_remaining_cycle_count[c][i] - cycles_passed)
            vars_remaining_cycles = dict((var, c - cycles_passed) for var, c in vars_remaining_cycles.items()
                                         if c > cycles_passed)
        else:
            cur_instructions_in_cycle += 1
        vars_remaining_cycles[var] = core['latency']
        for port in core['core']:
            assert core_remaining_cycle_count[port['name']][0] == 0
            core_remaining_cycle_count[port['name']][0] = port['latency']
            core_remaining_cycle_count[port['name']] = sorted(core_remaining_cycle_count[port['name']])
        return (cost, freeze((vars_remaining_cycles, core_remaining_cycle_count, cur_instructions_in_cycle, register_vals)))

    @memoize
    def evaluate_cost_memo(arg):
        schedule, core_state = unfreeze_gen(arg)
        schedule = unfreeze(schedule)
        (vars_remaining_cycles, core_remaining_cycle_count, cur_instructions_in_cycle, register_vals) = unfreeze(core_state)
        if len(schedule) == 0: return max([0] + list(vars_remaining_cycles.values()))
        (var, core, args), schedule = schedule[0], schedule[1:]
        cost, core_state = update_core_state(var, freeze(core), args, core_state)
        return cost + evaluate_cost_memo(freeze_gen((freeze(schedule), core_state)))


    def get_wait_times(var_cores, core_state):
        for var, core, args in var_cores:
            (vars_remaining_cycles, core_remaining_cycle_count, cur_instructions_in_cycle, register_vals) = unfreeze(core_state)
            changed, register_vals = update_register_vals_with_core_args(core, args, register_vals)
            cost, new_core_state = update_core_state(var, freeze(core), args, core_state)
            yield (cost, -len(reverse_dependencies.get(var, [])), changed, -core['latency'], var, core, args, new_core_state)

    def cmp_wait_time(v1, v2):
        (cost1, neg_len_deps1, changed1, neg_latency1, var1, core1, args1, new_core_state1) = v1
        (cost2, neg_len_deps2, changed2, neg_latency2, var2, core2, args2, new_core_state2) = v2
        if cost1 != cost2: return cmp(cost1, cost2)
        if core1['instruction'] == core2['instruction']:
            if changed1 != changed2: return cmp(changed1, changed2)
            if neg_len_deps1 != neg_len_deps2: return cmp(neg_len_deps1, neg_len_deps2)
            if neg_latency1 != neg_latency2: return cmp(neg_latency1, neg_latency2)
        if var1 != var2: return cmp(var1, var2)
        return cmp(v1, v2)

    def get_sorted_next_statements(next_var_cores, core_state):
        return sorted(get_wait_times(next_var_cores, core_state), cmp=cmp_wait_time)

    def add_cycle_info(schedule):
        core_state = freeze(make_initial_core_state())
        schedule_with_cycle_info = []
        cur_cycle = 0
        for var, core, args in schedule:
            cost, core_state = update_core_state(var, freeze(core), args, core_state)
            cur_cycle += cost
            schedule_with_cycle_info.append((var,
                                             {'start':cur_cycle, 'finish':cur_cycle + core['latency']},
                                             core))
        return schedule_with_cycle_info

    def evaluate_cost(schedule_with_cycle_info):
        return max(cycles['finish'] for var, cycles, core in reversed(schedule_with_cycle_info))


    var_names = get_var_names(data)
    lines = dict((line['out'], line) for line in data['lines'])

    @memoize
    def schedule_remaining(remaining_indices, core_state):
        def make_schedule(var, core, args):
            cost, new_core_state = update_core_state(var, freeze(core), args, core_state)
            extra_cost, schedule = schedule_remaining(tuple(i for i in remaining_indices if i != var), new_core_state)
            return cost + extra_cost, ([(var, core, args)] + schedule)
        next_statements = get_possible_next_statements(remaining_indices, dependencies)
        min_cost, min_schedule = None, None
        var_cores = [(var, core, (lines[var]['args'] if var in lines.keys() else (var,)))
                     for var in next_statements
                     for core in (lines[var]['cores'] if var in lines.keys() else possible_cores_for_line({'op':'LOAD', 'type':'uint64_t'}))]

        sorted_subset_next_statements = sorted_next_statements = get_sorted_next_statements(var_cores, core_state)
        if len(sorted_next_statements) > 0:
            pre_min_cost = sorted_next_statements[0][0]
#            print((pre_min_cost, tuple(var for cost2, var, core, new_core_state in sorted_next_statements if pre_min_cost == cost2)))
            sorted_subset_next_statements \
                = tuple((cost, var, core, args, new_core_state) for cost, reverse_dep_count, changed, neg_latency, var, core, args, new_core_state in sorted_next_statements
                        if pre_min_cost == cost)
            sorted_subset_next_statements = sorted_subset_next_statements[:1]
            if pre_min_cost == 0: sorted_subset_next_statements = sorted_subset_next_statements[:1]
        for cost, var, core, args, new_core_state in sorted_subset_next_statements:
            cost, schedule = make_schedule(var, core, args)
            if min_cost is None or cost < min_cost:
                min_cost, min_schedule = cost, schedule
#            return min_cost, min_schedule
        if min_cost is None:
            min_cost, min_schedule = evaluate_cost_memo(freeze_gen((freeze([]), core_state))), []
        return min_cost, min_schedule

    core_state = freeze(make_initial_core_state())
    cost, schedule = schedule_remaining(get_initial_indices(data), core_state) #, freeze_core_state(make_initial_core_state()))
    schedule_with_cycle_info = add_cycle_info(schedule)
    for var, cycles, core in schedule_with_cycle_info:
        if var in lines.keys():
            do_print(lines[var]['source'], ' // %s, start: %s, end: %s' % (core['instruction'], basepoint + cycles['start'], basepoint + cycles['finish']))
        else:
            do_print('%s = %s;' % (var, var), ' // %s, start: %s, end: %s' % (core['instruction'], basepoint + cycles['start'], basepoint + cycles['finish']))
    return basepoint + cost

data_list = parse_lines(get_lines('femulDisplay.log'))
basepoint = 0
for i, data in enumerate(data_list):
    with codecs.open('femulScheduled.log', 'w', encoding='utf8') as f:
        def do_print(v, comment):
            print(v + comment)
            f.write(v + comment + '\n')
        f.write(data['header'] + '\n')
        basepoint = schedule(data, basepoint, do_print)
        f.write(data['footer'] + '\n')
    print(basepoint)
    sys.exit(0)

print(basepoint)
