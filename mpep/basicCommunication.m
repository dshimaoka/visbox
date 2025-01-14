javaaddpath .
animal = 'luke1';
l = Logger.getLogger();
l.selectAnimal(animal);
p = Params('/home/luke/Dropbox/zpep_work/pfiles/ori12.p', '/home/luke/Dropbox/zpep_work/xfiles/');
p.variableMap('bigdiam') = 1;
p.variableMap('c') = 1;
p.variableMap('sf100') = 1;
p.variableMap('tf') = 1;
p.variableMap('x') = 1;
p.variableMap('y') = 1;
rp = p.render;
exp = Protocol(animal, 1, rp, 2);
com = TDTCommunicator();
% com.hosts = {'127.0.0.1'};
com.connect();
stim = StimulusServer();
stim.connect()
exp.run(stim, com)
stim.disconnect()