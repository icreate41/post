#include "includes/includes.h"
//------------------------------------------------------------------------------
int stoi(stdstr &str)
{
    int val;
    if(sscanf(str.c_str(), "%i", &val) == 0)
        throw std::runtime_error("Could not convert string to int");
    return val;
}
stdstr to_string(int val)
{
    char cstr[12];
    sprintf(cstr, "%i", val);
    return stdstr(cstr);
}
//------------------------------------------------------------------------------
int get_last_program()
{   
    stdstr line;
    fstream fs;
    fs.open((path + "selected").c_str(), ios::in | ios::out);
    try
    {
        getline(fs, line);
        return stoi(line);
    }
    catch (...)
    {
        fs.close();
        fs.open((path + "selected").c_str(), ios::in | ios::out | ios::trunc);
        line = "0";
        fs.write(line.c_str(), line.size());
        return 0;
    }
}
void set_last_program(int n)
{
    stdstr line = to_string(n);
    fstream fs;
    fs.open((path + "selected").c_str(), ios::in | ios::out | ios::trunc);
    fs.write(line.c_str(), line.size());
}
//------------------------------------------------------------------------------
Step::Step(short num, int count)
{
    number = num;
    var = vector<char>(count);
}
Step::Step(short num, short next, int time, const vector<char>& data)
{
    number = num;
    header.next = next;
    header.time = time;
    var = data;
}
//------------------------------------------------------------------------------
int Position::get_index()
{
    return _index;
}
list<Step>::iterator Position::get_iterator()
{
    return _iterator;
}
list<Step>::iterator Position::advance_back(int offset)
{
    offset = minmax<int>(offset, -_index, _container->size() - 1 - _index);
    _index += offset;
    advance(_iterator, offset);
    return _iterator;
}
list<Step>::iterator Position::advance_end(int offset)
{
    offset = minmax<int>(offset, -_index, _container->size() - _index);
    _index += offset;
    advance(_iterator, offset);
    return _iterator;
}
bool Position::operator==(const Position& rhs)
{       
    return this->_container == rhs._container && this->_index == rhs._index &&
        this->_iterator == rhs._iterator;
}
bool Position::operator==(const list<Step>::iterator& rhs)
{
    return this->_iterator == rhs;
}
bool Position::operator!=(const list<Step>::iterator& rhs)
{
    return this->_iterator != rhs;
}
void Position::update_iterator(list<Step>::iterator iterator)
{
    _iterator = iterator;
}
void Position::fixed_index(Position marker)
{
    this->_iterator = marker.advance_end(this->_index - marker._index);
}
void Position::fixed_iterator()
{
    this->_index = distance(_container->begin(), this->_iterator);
}
Position::Position(int index, list<Step> *container)
{
    _container = container;
    _index = 0;
    _iterator = _container->begin();
    advance_end(index);
}
//------------------------------------------------------------------------------
void update()
{
    static short counter;
    mem.setShort("%counter", ++counter);
}
void GetData(list<Tag>& tags, vector<char>& buffer)
{
    int offset = 0;
    for(list<Tag>::iterator it = tags.begin(); it != tags.end(); it++)
    {   
        if(it->offset >= 0)
            mem.get(it->offset, &buffer[offset], sizes[it->type]);
        offset += sizes[it->type];
    }
}
void SetData(list<Tag>& tags, vector<char>& buffer)
{
    int offset = 0;
    for(list<Tag>::iterator it = tags.begin(); it != tags.end(); it++)
    {   
        if(it->offset >= 0)
            mem.set(it->offset, &buffer[offset], sizes[it->type]);
        offset += sizes[it->type];
    }
}
//------------------------------------------------------------------------------
list<Step>::iterator Program::prev(list<Step>::iterator it)
{
    return --it;
}
list<Step>::iterator Program::next(list<Step>::iterator it)
{
    return ++it;
}    
void Program::print()
{   
    mem.setShort("%current program", prognum);
    mem.setShort("%current step", step.get_index());
    mem.setLong ("%current time", header.time);
    mem.setBool ("%run", run);
    mem.setBool ("%continuation", continuation);
    mem.setShort("%window", window.get_index());
    mem.setShort("%step count", header.count);
    mem.setShort("%repeat count", header.repeat);
    Position pos = window;
    for (int i = 0; i < 5; i++)
    {
        if (pos == steps.end())
            break;
        mem.setLong(("%time"+to_string(i)).c_str(), pos.get_iterator()->header.time);
        SetData(output[i], pos.get_iterator()->var);
        pos.advance_end(1);
    }
    if (run == true)
    {   
        mem.setLong("%time5", step.get_iterator()->header.time);
        SetData(output[5], step.get_iterator()->var);
    }    
}
void Program::read_prog_header()
{
    fs.seekg(offset, fs.beg);
    fs.read((char*)&header, sizeof(ProgHeader));
}
void Program::write_prog_header()
{
    fs.seekg(offset, fs.beg);
    fs.write((char*)&header, sizeof(ProgHeader));
    fs.flush();
}  
void Program::read_step(list<Step>::iterator it)
{
    fs.seekg(offset + sizeof(ProgHeader) + it->number * blocksize, fs.beg);
    fs.read((char*)&it->header, sizeof(StepHeader));
    fs.read(it->var.data(), datasize);
}
void Program::write_step(list<Step>::iterator it)
{
    fs.seekg(offset + sizeof(ProgHeader) + it->number * blocksize, fs.beg);
    fs.write((char*)&it->header, sizeof(StepHeader));
    fs.write(it->var.data(), datasize);
    fs.flush();
}
void Program::write_step(int n, list<Step>::iterator it)
{
    fs.seekg(offset + sizeof(ProgHeader) + n * blocksize, fs.beg);
    fs.write((char*)&it->header, sizeof(StepHeader));
    fs.write(it->var.data(), datasize);
    fs.flush();
}
void Program::write_step_header(list<Step>::iterator it)
{
    fs.seekg(offset + sizeof(ProgHeader) + it->number * blocksize, fs.beg);
    fs.write((char*)&it->header, sizeof(StepHeader));
    fs.flush();
}
void Program::time_passed(int seconds_passed, bool advance_next)
{
    static int dt;
    if (run == false)
        return;
    dt += seconds_passed;
    header.time += seconds_passed;
    if (header.time >= step.get_iterator()->header.time)
    {
        dt = 0;
        header.time =  step.get_iterator()->header.time;
        if( advance_next)
            advance_step(1);
    }
    else if (dt > 120)
    {
        dt = 0;
        write_prog_header();
    }
    print();
}
void Program::start_program(Position pos, int time)
{
    if (run)
        return;
    run = true;
    step = pos;
    header.step = step.get_index();
    header.time = time;
    write_prog_header();
    time_passed(0, true);
}
bool Program::try_open(const list<stdstr>& title)
{
    stdstr line;
    fs.open((path + to_string(prognum)).c_str(), ios::in|ios::out|ios::binary);
    if (!fs)
        return false;
    fs.seekg(0, fs.end);
    int length = fs.tellg();
    fs.seekg(0, fs.beg);
    if (length > 1024 * 1024)
        return false;
    list<stdstr>::const_iterator it = title.begin();
    while (getline(fs, line))
    {
        if (line != *it)
            return false;
        it++;
        if (it == title.end())
        {
            offset = fs.tellg();
            if (offset + sizeof(ProgHeader) + 1000 * blocksize != length)
                return false;
            read_prog_header();
            if (header.count  < 1 || header.count  > 1000 || 
                header.head   < 0 || header.head   > 999  ||
                header.repeat < 0 || header.repeat > 999  ||
                header.step   < 0 || header.step   > header.count -1 ||
                header.time   < 0 || header.time   > 31536000)
                return false;
            short pos = header.head;
            for (int i = 0; i < header.count; i++)
            {
                try { bitmap.insert(pos); }
                catch (...) { return false; }
                list<Step>::iterator el = steps.insert(steps.end(), Step(pos, datasize));
                read_step(el);
                if (el->header.time < 1)
                    return false;
                pos = el->header.next;
            }
            return true;
        }
    }
    return false;
}
void Program::create(list<stdstr>& title, const vector<char>& def)
{
    if (fs.is_open())
        fs.close();
    steps.clear();
    bitmap.clear();
    fs.open((path + to_string(prognum)).c_str(), ios::in|ios::out|ios::trunc|ios::binary);
    if (!fs)
        throw std::runtime_error("Could not create file");
    for (list<stdstr>::iterator it = title.begin(); it != title.end(); it++)
    {
        stdstr out = *it + "\n";
        fs.write(out.c_str(), out.size());
    }
    offset = fs.tellg();
    header.count = 1;
    header.head = 0;
    header.step = 0;
    header.repeat = 0;
    header.time = 0;
    write_prog_header();
    bitmap.insert(0);
    steps.insert(steps.end(),Step(0, 1000, 3600, def));
    for (int i = 0; i < 1000; i++)
        write_step(i, steps.begin());
    fs.flush();
}
//------------------------------------------------------------------------------
Program::Program(list<stdstr> &title, list<Tag> *out, vector<char>& def, int size, int n)
: bitmap(1000), window(0, &steps), step(0, &steps), output(out)
{   
    prognum   = minmax(n, 0, 999);
    datasize  = minmax(size, 0, 1024);
    blocksize = sizeof(StepHeader) + datasize;
    if (try_open(title) == false)
        create(title, def);
    window = Position(0, &steps);
    step   = Position(header.step, &steps);
    run    = false;
    continuation = true;
    print();
} 
void Program::advance_step(int off)
{
    step.advance_end(off);
    if (step == steps.end())
    {
        step = Position(0, &steps);
        if (run)
        {
            if (run = header.repeat > 0)
                header.repeat--;
            else
                continuation = false;
        }
    }
    header.step = step.get_index();
    header.time = 0;
    write_prog_header();
    print();
}
void Program::tick(int seconds_passed, bool advance_next)
{
    seconds_passed = minmax(seconds_passed, 0, 31536000);
    time_passed(seconds_passed, advance_next);
}
void Program::start()
{
    continuation = false;
    start_program(Position(0, &steps), 0);
}
void Program::resume()
{
    continuation = true;
    start_program(step, header.time);
}
void Program::stop()
{
    run = false;
    continuation = true;
    write_prog_header();
    print();
}
void Program::change_repeat(int n)
{
    n = minmax(n, 0, 999);
    header.repeat = n;
    write_prog_header();
    print();
}
void Program::advance_window(int off)
{
    window.advance_back(off);
    print();
}
void Program::insert(int off, int time, const vector<char>& def)
{
    if (header.count == 1000)
        return;
    time = minmax(time, 1, 31536000);
    header.count++;
    int newpos  = bitmap.insert();
    int nextpos = 1000;
    Position pos = window;
    pos.advance_end(off);
    if (pos == steps.begin())
        header.head = newpos;
    else
    {
        list<Step>::iterator p = prev(pos.get_iterator());
        p->header.next = newpos;
        write_step_header(p);
    }
    if (pos != steps.end())
        nextpos = pos.get_iterator()->number;
    pos.update_iterator(steps.insert(pos.get_iterator(), Step(newpos, nextpos, time, def)));
    write_step(pos.get_iterator());
    window.fixed_index(pos);
    step.fixed_iterator();
    header.step = step.get_index();
    write_prog_header();
    print();
}   
void Program::erase(int off)
{
    if (header.count == 1)
        return;
    header.count--;
    int nextpos = 1000;
    Position pos = window;
    pos.advance_back(off);
    bitmap.erase(pos.get_iterator()->number);
    if (pos == step)
        advance_step(1);
    if (pos == window && pos == prev(steps.end()))
        window.advance_back(-1);
    if (pos != prev(steps.end()))
        nextpos = next(pos.get_iterator())->number;
    if (pos == steps.begin())
        header.head = nextpos;
    else
    {
        list<Step>::iterator p = prev(pos.get_iterator());
        p->header.next = nextpos;
        write_step_header(p);
    }
    pos.update_iterator(steps.erase(pos.get_iterator()));
    window.fixed_index(pos);
    step.fixed_iterator();
    header.step = step.get_index();
    write_prog_header();
    print();
}
void Program::assign(int off, int time, const vector<char>& var)
{
    time = minmax(time, 1, 31536000);
    Position pos = window;
    pos.advance_back(off);
    pos.get_iterator()->header.time = time;
    pos.get_iterator()->var = var;
    write_step(pos.get_iterator());
    if(pos == step)
        advance_step(0);
    print();
}
//------------------------------------------------------------------------------