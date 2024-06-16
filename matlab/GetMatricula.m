function [textoMat] = GetMatricula(IEnt, redSel)

    if (strcmp(redSel,'alexnet') == 1)
      load netTransferPlataformaAlexNet.mat
    else
      load netTransferPlataformaGoogleNet.mat
    end
    I=IEnt;
    figure(6); imshow(I);
    [M,N,c] = size(I);
    
    HSV = rgb2hsv(I);
    G = HSV(:,:,3);
    level = graythresh(G);
    negra = imbinarize(G,level);
    
    se = strel('disk',3);
    Binaria2 = imopen(negra,se);
    Binaria3 = imclose(Binaria2,se);
    Binaria4 = bwmorph(Binaria3,'clean');
    [Etiquetas,NumRegiones] = bwlabel(Binaria4);
    
    PropRegiones = regionprops(Etiquetas,'all');
    
    TamArea = 200;
    RegionesSeleccionadas = zeros(1,NumRegiones);
    for i=1:1:NumRegiones
      if PropRegiones(i).Area > TamArea
          RegionesSeleccionadas(i) = 1;
      end
    end
    
    MatriculasCandidatas = zeros(1,NumRegiones);
    for i=1:1:NumRegiones
        if RegionesSeleccionadas(i) == 1
            Rectangulo = round(PropRegiones(i).BoundingBox);
            XSupIzda = Rectangulo(1);
            if XSupIzda <=0; XSupIzda = 1; end
            YSupIzda = Rectangulo(2);
            if YSupIzda <=0; YSupIzda = 1; end
            
            ancho =  Rectangulo(3); alto = Rectangulo(4);
        
            XSupDcha =  round(XSupIzda + ancho);
            if XSupDcha > N; XSupDcha = N; end
          
            YInfIzda =  round(YSupIzda + alto);
            if YInfIzda > M; YInfIzda = M; end
        
            Recorte = I(YSupIzda:1:YInfIzda,XSupIzda:1:XSupDcha,:);     
            
            if (strcmp(redSel,'alexnet') == 1)
               Ir = imresize(Recorte, [227 227]);
            else
               Ir = imresize(Recorte, [224 224]);
            end

            [label, Error]  = classify(netTransfer,Ir);
            
            MaxValor = max(Error);
            if strcmp(char(label),'Matricula') && (MaxValor > 0.6)
                figure(7); imshow(Ir);title(label);
                waitforbuttonpress
               MatriculasCandidatas(i) = MaxValor;
            end
        end
    end
    
    
    MaxP = max(MatriculasCandidatas);
    [row,col,v] = find(MatriculasCandidatas == MaxP);
    
    if  length(col) ~= 1
        textoMat = '';
        %IMat = I;
    else
       
        Rectangulo = round(PropRegiones(col).BoundingBox);

        XSupIzda = Rectangulo(1);
        if XSupIzda <=0; XSupIzda = 1; end
        YSupIzda = Rectangulo(2);
        if YSupIzda <=0; YSupIzda = 1; end
                
        ancho =  Rectangulo(3); alto = Rectangulo(4);
            
        XSupDcha =  round(XSupIzda + ancho);
        if XSupDcha > N; XSupDcha = N; end

        YInfIzda =  round(YSupIzda + alto);
        if YInfIzda > M; YInfIzda = M; end
        
        %% 
        
        %Deteción automática y reconocimiento de texto usando MSER y OCR
        
        IMat = I(YSupIzda:1:YInfIzda,XSupIzda:1:XSupDcha,:);
        
        matricula = getTextoMSERYOCR(IMat);
        junto = "";
        ii = length(matricula);
        while (ii>0)
            junto = strcat(junto, matricula(ii).Text);
            ii = ii-1;
        end
        textoMat = junto;
    end
   
end

