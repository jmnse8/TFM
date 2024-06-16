%% Estimating Optical Flow and classification of 
% This example uses the Farneback Method to to estimate the direction and
% speed of moving cars in the video

%% INTERESANTE (FINAL DEL VIDEO) PARA VER APLICACIÓN
% Ver canal Youtube como ejemplo de aplicación: https://www.youtube.com/watch?v=jGbl4ADExL0

%% Read the video into MATLAB
%close all; clear all;

%% Definición del canal Thing Speak
ChannelID   = 1012384;
readAPIKey  = '9TI4K11SPDSQVZQ0';
writeAPIKey = '8F4OQAMY9AUSUDTS';

%% Contadores para determinar el número de buses y coches que pasan por una determinada zona
NumBuses  = 0;
NumCoches = 0;
NumMotos  = 0;

% Para guardar el vídeo
sssMPEG = '.\videoFinal.avi';
videoMPEG = VideoWriter(sssMPEG,'Archival');
open(videoMPEG)

%% Cargar la red previamente entrenada
load netTransferMovimiento
sz = netTransfer.Layers(1).InputSize;

% Aplicación del método de flujo óptico: tres métodos
opticFlow = opticalFlowFarneback; %Farneback 
%opticFlow = opticalFlowLK;       %Lukas-Kanade
%opticFlow = opticalFlowHS;       %Horn-Schunck
reset(opticFlow);

N = 5; % Número de fotogramas que deseas capturar
frameGrayArray = cell(1, N); % Inicializa un cell array para almacenar los fotogramas en escala de grises

[M, N, ~] = size(snapshot(camara,'immediate')); % Obtiene el tamaño de los fotogramas capturados

for i = 1:N
    frameRGB = snapshot(camara,'immediate');
    frameGray = im2gray(frameRGB);
    frameGrayArray{i} = frameGray; % Almacena el fotograma en escala de grises en el cell array
end

% Ahora puedes usar el array de fotogramas gray en tus cálculos con estimateFlow
%flow = estimateFlow(opticFlow, frameGrayArray);

%% Estimate Optical Flow of each frame of Video

for i = 1:N
  flow = estimateFlow(opticFlow,frameGrayArray{i});

  figure(2);imshow(frameGrayArray{i});impixelinfo
  hold on
  % Plot the flow vectors
  plot(flow,'DecimationFactor',[25 25],'ScaleFactor', 2)
  % Find the handle to the quiver object
  q = findobj(gca,'type','Quiver');
  % Change the color of the arrows to red
  q.Color = 'r';
  drawnow
  hold off
  

  if i > 2
    MagnitudFlow    = mat2gray(flow.Magnitude);
    OrientacionFlow = flow.Orientation;
    level = mean2(MagnitudFlow)+std2(MagnitudFlow);
    BWMagFlow = MagnitudFlow > level;

    [Labels,Nlabels] = bwlabel(BWMagFlow);
    %figure(3); imagesc(Labels); impixelinfo; colorbar
    RProp   = regionprops(Labels,'all');
    RPropRed   = regionprops(Labels,frameRGB(:,:,1),'all');
    RPropGreen = regionprops(Labels,frameRGB(:,:,2),'all');
    RPropBlue  = regionprops(Labels,frameRGB(:,:,3),'all');
    RPropOrientacion  = regionprops(Labels,OrientacionFlow,'all');

    
    % Restricción de las áreas candidatas, que superen un determinado
    % umbral Th = 500 en número de píxeles
    Th = 500;
    AreasCandidatas = zeros(1,Nlabels);
    for j=1:1:Nlabels
      if RProp(j).Area > Th
        AreasCandidatas(j) = 1;
      end
    end
    
  amp = 0;
  for h=1:1:Nlabels
    if AreasCandidatas(h) == 1
      XSupIzda =  round(RProp(h).BoundingBox(1)+amp);
      if XSupIzda <=0; XSupIzda = 1; end
      YSupIzda =  round(RProp(h).BoundingBox(2)+amp);  
      if YSupIzda <=0; YSupIzda = 1; end
    
      XSupDcha =  round(XSupIzda + RProp(h).BoundingBox(3) + amp);
      if XSupDcha > N; XSupDcha = N; end
      YSupDcha =  YSupIzda; 
     
      XInfIzda =  XSupIzda;
      YInfIzda =  round(YSupIzda + RProp(h).BoundingBox(4) + amp);
      if YInfIzda > M; YInfIzda = M; end

      XInfDcha =  XSupDcha; 
      YInfDcha =  YInfIzda;
    
      Recorte = frameRGB(YSupIzda:1:YInfIzda,XSupIzda:1:XSupDcha,:);
      %figure(4); imshow(Recorte); hold on
      RecorteBW = BWMagFlow(YSupIzda:1:YInfIzda,XSupIzda:1:XSupDcha,:);

      [aar, bbr, ssr] = size(Recorte);
      R = imresize(Recorte, [sz(1) sz(2)], 'bilinear');       
      %figure(4); imshow(R); hold on
      
      %% Clasifcación propiamente dicha mediante la red neuronal
      [label, Error]  = classify(netTransfer,R);
      [MEt,MaxEt] = max(Error);
      %disp('Label ='); disp(label)
      %disp('Error ='); disp(Error)
      
      % Aquí debemos tomar una decisión para determinar si el coche va en
      % buen sentido o mal. Teniendo en cuenta la posición de la cámara en
      % la carretera. Por la parte izquierda el flujo tendrá una
      % orientación diferente a la derecha. 
      Orientacion = RPropOrientacion(h).MeanIntensity;

      if (label ~= 'Asfalto') && (label ~= 'Lineas') && (label ~= 'Muro')... 
         && (MEt >= 0.5)%... 
         %&& RPropOrientacion(h).Centroid(2) > 500 && RPropOrientacion(h).Centroid(2) < 950 % Sólo si atraviesan una región dada
        %figure(5); bar(Error)
        
        switch label
        case 'Bus'
          color = 'yellow'; texto = 'Bus';
          NumBuses = NumBuses + 1;
        case 'CamionFurgo'
          color = 'white'; texto = 'Camion-furgo';
        case 'CocheDelantera'
          color = 'blue'; texto = 'Car Frontal';
          NumCoches = NumCoches + 1;
        case 'CocheTrasera'
            %ICoche = Recorte(YSupIzda:1:YInfIzda,XSupIzda:1:XSupDcha,:);
          [testoMat] = GetMatricula(Recorte,'alexnet');
          color = 'red'; texto = testoMat;
          NumCoches = NumCoches + 1;
        case 'Moto'
          color = 'green'; texto = 'Moto';
          NumMotos = NumMotos + 1;
        case 'Asfalto'
          color = 'black'; texto = 'Asfalto';
        case 'Lineas'
          color = 'black'; texto = 'Lineas';
        case 'Muro'
          color = 'black'; texto = 'Muro';
        end
        figure(2); hold on; text(XSupDcha,YSupDcha,texto)
        line([XSupIzda,XSupDcha],[YSupIzda,YSupDcha],'LineWidth',3,'Color',color)
        line([XSupIzda,XInfIzda],[YSupIzda,YInfIzda],'LineWidth',3,'Color',color)
        line([XSupDcha,XInfDcha],[YSupDcha,YInfDcha],'LineWidth',3,'Color',color)
        line([XInfIzda,XInfDcha],[YInfIzda,YInfDcha],'LineWidth',3,'Color',color)
        hold off
        
      end
    end
  end
  end
  saveas(figure(2),'Figura.bmp');
  frameFigure = imread('Figura.bmp');
  if i > start+2
    writeVideo(videoMPEG,frameFigure);
  end 
  
end

close(videoMPEG); %se cierra el video grabado

%% Escritura en ThingSpeak

%thingSpeakWrite(ChannelID,'Fields',[1,2,3],'Values',{NumCoches,NumBuses,NumMotos},'WriteKey',writeAPIKey)
%pause(2); pause(2); pause(2); pause(2); pause(2); pause(2); pause(2); pause(2); pause(2);

% Comprobamos que los datos se han escrito correctamente 
%data = thingSpeakRead(ChannelID,'Fields',[1,2,3],'ReadKey',readAPIKey,NumPoints=3,OutputFormat='TimeTable')
