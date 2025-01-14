function [bytes address port] = receiveFromSocket(socket, bufferSize, timeout)
%RECEIVEFROMSOCKET receive packet from socket.
% bufferSize: size of data of packet - if the recieved packet is too big
% it's data will be truncated.
% timeout: length of time (milisec) to block for before returning an error if no 
% packet recieved. 0 for no timeout (can block forever!)
import java.net.*;
rp = DatagramPacket(Utils.getByteArray(bufferSize), int32(bufferSize));
socket.setSoTimeout(timeout);
socket.receive(rp);
bytes = rp.getData()';
bytes = bytes(1:rp.getLength());
address = char(rp.getAddress().getHostAddress()); % address as ip string
port = rp.getPort(); % port this packet came from on sender
disp(['Received "' char(bytes) '" from ' address ':' num2str(port)]);
end

