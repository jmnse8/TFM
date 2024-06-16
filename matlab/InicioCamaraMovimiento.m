%% Preparacion del dispositivo

% IMPORTANTE: si se queda el objeto m abierto, genera problemas, siendo necesario eliminarlo en 
% la l�nea de comandos haciendo: clear m

clear all; close all;

%% Borrado de objetos previos
if exist('m','var')
    clear m;
end

if exist('camara','var')
    clear camara;
end

%% Crear objeto
m = mobiledev;

% Definir c�mara
camara = camera(m,'back');
camara.Autofocus = 'on';

%% Cargar la Red AlexNet si no existe
load ('netTransferMovimiento')
