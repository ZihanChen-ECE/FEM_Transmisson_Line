clear
clc

%%
%---------------------------------------------------------------------%
% Read and pre-condition the mesh file
%---------------------------------------------------------------------%
%gmsh_filename = 'example_2d.msh';
gmsh_filename = 'TRL1.msh';

  fprintf ( 1, '\n' );
  fprintf ( 1, 'GMSH_IO_TEST02:\n' );
  fprintf ( 1, '  Read data from a file.\n' );
%
%  Get the data size.
%
  [ node_num, m, element_num, element_order ] = gmsh_size_read ( gmsh_filename );
%
%  Print the sizes.
%
  fprintf ( 1, '\n' );
  fprintf ( 1, '  Node data read from file "%s"\n', gmsh_filename );
  fprintf ( 1, '\n' );
  fprintf ( 1, '  Number of nodes = %d\n', node_num );
  fprintf ( 1, '  Spatial dimension = %d\n', m );
  fprintf ( 1, '  Number of elements = %d\n', element_num );
  fprintf ( 1, '  Element order = %d\n', element_order );
%
%  Get the data.
%

   [ node_x, element_node ] = gmsh_data_read ( gmsh_filename, m, node_num, element_order, element_num );

    node_xT = node_x';
    element_nodeT = element_node'; 
    
     %discard those useless points in element_nodeT
   for ii = 1:element_num
      if(element_nodeT(ii,1)==0)
          break;
      end
   end
   element_nodeT(ii:end,:)=[]; 
    
    
   %%
%---------------------------------------------------------------------%
%2D static Electrical problem (poison's equation) with FEM method
%---------------------------------------------------------------------%
mur = 1;
mu = pi*4e-7;
%omega = 2*pi*[10e6,100e6,1e9,10e9,100e9,1e12];
omega = 2*pi*[10e6];
sigmaAL2O3 = 3.6e7;

Eimp = 1;

[Nelem,Nvertex] = size(element_nodeT);
ENode = zeros(1,Nvertex);
Ex = zeros(Nvertex,1);
Ey = zeros(Nvertex,1);
ae = zeros(Nvertex,1);
be = zeros(Nvertex,1);
ce = zeros(Nvertex,1);
Eb = zeros(Nvertex,1);

u = zeros(node_num,4);
% K = zeros(node_num,node_num);
% b = zeros(node_num,1);
I = zeros(4,4);
V = eye(4,4);
Z = zeros(4,4);
Z11 = zeros(1,length(omega));  
Z13 = zeros(1,length(omega));

k = zeros(3,3);
for io = 1:length(omega)
    beta = 1i*omega(io)*mu;
    
    K = sparse(node_num,node_num);
    b = sparse(node_num,4);
    
for ii = 1:Nelem
    ENode(1,:) = element_nodeT(ii,:);  %Find the node number for each element
    %get the position of x and y for each element node
    for j = 1:Nvertex
        Ex(j) = node_xT(ENode(j),1);
        Ey(j) = node_xT(ENode(j),2);   
    end
    for j = 1:Nvertex
        ae(1) = Ex(2)*Ey(3)-Ey(2)*Ex(3);
        ae(2) = Ex(3)*Ey(1)-Ey(3)*Ex(1);
        ae(3) = Ex(1)*Ey(2)-Ey(1)*Ex(2);
        be(1) = Ey(2)-Ey(3);
        be(2) = Ey(3)-Ey(1);
        be(3) = Ey(1)-Ey(2);
        ce(1) = Ex(3)-Ex(2);
        ce(2) = Ex(1)-Ex(3);
        ce(3) = Ex(2)-Ex(1);
    end
    EArea = abs(1/2*(Ex(2)*Ey(3)-Ey(2)*Ex(3)-Ex(1)*(Ey(3)-Ey(2))+Ey(1)*(Ex(3)-Ex(2))));
    
    maxX = max(Ex(:));
    minX = min(Ex(:));
    maxY = max(Ey(:));
    minY = min(Ey(:));
    
    if (((maxX<=16e-6 && minX>=15e-6) && (minY>=11e-6 && maxY<=12e-6))||((maxX<=18e-6 && minX>=17e-6) && (minY>=11e-6 && maxY<=12e-6))...
        ||((maxX<=20e-6 && minX>=19e-6) && (minY>=11e-6 && maxY<=12e-6))||((maxX<=23e-6 && minX>=12e-6) && (minY>=9e-6 && maxY<=10e-6)))
    sigma = sigmaAL2O3;
    else
    sigma = 0;
    end
    
    
    %calculate Kij for the element
    k(1,1) = (1/(4*EArea))*((Ey(2)-Ey(3))^2+(Ex(3)-Ex(2))^2)+EArea/12*beta*(1+1)*sigma;
    k(1,2) = (1/(4*EArea))*((Ey(2)-Ey(3))*(Ey(3)-Ey(1))+(Ex(3)-Ex(2))*(Ex(1)-Ex(3)))+EArea/12*beta*(1)*sigma;
    k(1,3) = (1/(4*EArea))*((Ey(2)-Ey(3))*(Ey(1)-Ey(2))+(Ex(3)-Ex(2))*(Ex(2)-Ex(1)))+EArea/12*beta*(1)*sigma;
    k(2,1) = (1/(4*EArea))*((Ey(3)-Ey(1))*(Ey(2)-Ey(3))+(Ex(1)-Ex(3))*(Ex(3)-Ex(2)))+EArea/12*beta*(1)*sigma;
    k(2,2) = (1/(4*EArea))*((Ey(3)-Ey(1))^2+(Ex(1)-Ex(3))^2)+EArea/12*beta*(1+1)*sigma;
    k(2,3) = (1/(4*EArea))*((Ey(3)-Ey(1))*(Ey(1)-Ey(2))+(Ex(1)-Ex(3))*(Ex(2)-Ex(1)))+EArea/12*beta*(1)*sigma;
    k(3,1) = (1/(4*EArea))*((Ey(1)-Ey(2))*(Ey(2)-Ey(3))+(Ex(2)-Ex(1))*(Ex(3)-Ex(2)))+EArea/12*beta*(1)*sigma;
    k(3,2) = (1/(4*EArea))*((Ey(1)-Ey(2))*(Ey(3)-Ey(1))+(Ex(2)-Ex(1))*(Ex(1)-Ex(3)))+EArea/12*beta*(1)*sigma;
    k(3,3) = (1/(4*EArea))*((Ey(1)-Ey(2))^2+(Ex(2)-Ex(1))^2)+EArea/12*beta*(1+1)*sigma;

    %update K with kij
    for j = 1:Nvertex
        for m = 1:Nvertex
        K(ENode(j),ENode(m)) = K(ENode(j),ENode(m)) + k(j,m);
        end
    end   

    
   
    
    %excite conductors
    for is = 1:4
        if ((maxX<=16e-6 && minX>=15e-6) && (minY>=11e-6 && maxY<=12e-6) && is == 1) % conductor 1
            sigma = sigmaAL2O3;
            for j = 1:Nvertex
                Eb(j) = EArea/3*mu*sigma*Eimp;
                b(ENode(j),is) = b(ENode(j),is) + Eb(j);
            end
 
        end


        if ((maxX<=18e-6 && minX>=17e-6) && (minY>=11e-6 && maxY<=12e-6) && is == 2) %conductor 2
            sigma = sigmaAL2O3;
            for j = 1:Nvertex
                Eb(j) = EArea/3*mu*sigma*Eimp;
                b(ENode(j),is) = b(ENode(j),is) + Eb(j);
            end

        end
        
        
        if ((maxX<=20e-6 && minX>=19e-6) && (minY>=11e-6 && maxY<=12e-6) && is == 3) %conductor 3
            sigma = sigmaAL2O3;
            for j = 1:Nvertex
                Eb(j) = EArea/3*mu*sigma*Eimp;
                b(ENode(j),is) = b(ENode(j),is) + Eb(j);
            end
        end

        if ((maxX<=23e-6 && minX>=12e-6) && (minY>=9e-6 && maxY<=10e-6) && is == 4) %conductor 4
            sigma = sigmaAL2O3;
            for j = 1:Nvertex
                Eb(j) = EArea/3*mu*sigma*Eimp;
                b(ENode(j),is) = b(ENode(j),is) + Eb(j);
            end
        end

    end
    
    
end


%%
%Apply BC.
%First I deal with Dirichlet BC for phi = 1, as the source
%Find the position of these nodes
% Snode = zeros(1,1);
% Sm = 1;

%%Then I deal with Dirichlet BC for phi = 0
%Find the position of these nodes
Bnode = zeros(1,1);
Bm = 1;

for ii = 1:node_num
       if node_xT(ii,2)==0 || node_xT(ii,1)==0 || node_xT(ii,2)==24e-6 || node_xT(ii,1)==35e-6 %|| node_xT(i,2)==1%Depends on the scope of the region
               Bnode(Bm) = ii;
               Bm = Bm+1;
       end
%        if (node_xT(ii,2)==0.06 && node_xT(ii,1)>=0.275 && node_xT(ii,1)<0.33) ...
%                ||(node_xT(ii,2)==0.1 && node_xT(ii,1)>=0.275 && node_xT(ii,1)<0.33)...
%                ||(node_xT(ii,1)==0.33 && node_xT(ii,2)>=0.06 && node_xT(ii,2)<=0.1)
%                Snode(Sm) = ii;
%                Sm = Sm+1;
%        end
end

%Modify K and b with source node
% for ii=1:length(Snode)
%     K(Snode(ii),:)=0;
%     K(Snode(ii),Snode(ii))=1;
%     b(Snode(ii)) = 1;
% end

%reduce K and b by Dirichlet BC
%mapping matrix
M = eye(node_num,node_num);

 Z = length(Bnode);
% 
while Z > 0
    K(Bnode(Z),:)=[];
    K(:,Bnode(Z))=[];

    b(Bnode(Z),:) = [];

    M(Bnode(Z),:) = [];
    Z = Z-1;
end
 unew = zeros(length(u)-length(Bnode),4);

 %solver u by K and b
 for is = 1:4
    unew(:,is) = K\b(:,is);
    u(:,is) = M\unew(:,is);
 end

 
%calculate I 
sigma = sigmaAL2O3;
for ii = 1:Nelem
    ENode(1,:) = element_nodeT(ii,:);  %Find the node number for each element
    %get the position of x and y for each element node
    for j = 1:Nvertex
        Ex(j) = node_xT(ENode(j),1);
        Ey(j) = node_xT(ENode(j),2);   
    end
    Cx = sum(Ex)/3;
    Cy = sum(Ey)/3;
    for j = 1:Nvertex
        ae(1) = Ex(2)*Ey(3)-Ey(2)*Ex(3);
        ae(2) = Ex(3)*Ey(1)-Ey(3)*Ex(1);
        ae(3) = Ex(1)*Ey(2)-Ey(1)*Ex(2);
        be(1) = Ey(2)-Ey(3);
        be(2) = Ey(3)-Ey(1);
        be(3) = Ey(1)-Ey(2);
        ce(1) = Ex(3)-Ex(2);
        ce(2) = Ex(1)-Ex(3);
        ce(3) = Ex(2)-Ex(1);
    end
    EArea = abs(1/2*(Ex(2)*Ey(3)-Ey(2)*Ex(3)-Ex(1)*(Ey(3)-Ey(2))+Ey(1)*(Ex(3)-Ex(2))));
    
    maxX = max(Ex(:));
    minX = min(Ex(:));
    maxY = max(Ey(:));
    minY = min(Ey(:));
    
    for is = 1:4
        %if(is == 1) %Calculate I1,I2,I3,I4 excited by source is(on conductor is)
            if ((maxX<=16e-6 && minX>=15e-6) && (minY>=11e-6 && maxY<=12e-6))
                Ne = zeros(3,1);
                     for j = 1:3
                        Ne(j) = 1/2/EArea*(ae(j)+be(j)*Cx+ce(j)*Cy); 
                     end
                CPhi = Ne(1)*u(ENode(1),is)+Ne(2)*u(ENode(2),is)+Ne(3)*u(ENode(3),is);
                I(1,is) = I(1,is) + -1i*omega(io)*sigma*CPhi*EArea;       
            end
            if ((maxX<=18e-6 && minX>=17e-6) && (minY>=11e-6 && maxY<=12e-6))
                Ne = zeros(3,1);
                     for j = 1:3
                        Ne(j) = 1/2/EArea*(ae(j)+be(j)*Cx+ce(j)*Cy); 
                     end
                 CPhi = Ne(1)*u(ENode(1),is)+Ne(2)*u(ENode(2),is)+Ne(3)*u(ENode(3),is);
                I(2,is) = I(2,is) + -1i*omega(io)*sigma*CPhi*EArea;       
            end
            if ((maxX<=20e-6 && minX>=19e-6) && (minY>=11e-6 && maxY<=12e-6))
                Ne = zeros(3,1);
                     for j = 1:3
                        Ne(j) = 1/2/EArea*(ae(j)+be(j)*Cx+ce(j)*Cy); 
                     end
                 CPhi = Ne(1)*u(ENode(1),is)+Ne(2)*u(ENode(2),is)+Ne(3)*u(ENode(3),is);
                I(3,is) = I(3,is) + -1i*omega(io)*sigma*CPhi*EArea;       
            end
            if ((maxX<=23e-6 && minX>=12e-6) && (minY>=9e-6 && maxY<=10e-6))
                Ne = zeros(3,1);
                     for j = 1:3
                        Ne(j) = 1/2/EArea*(ae(j)+be(j)*Cx+ce(j)*Cy); 
                     end
                 CPhi = Ne(1)*u(ENode(1),is)+Ne(2)*u(ENode(2),is)+Ne(3)*u(ENode(3),is);
                I(4,is) = I(4,is) + -1i*omega(io)*sigma*CPhi*EArea;       
            end
            
            
            
       % end
    end
end

I(1,1) = I(1,1) + (sigma*Eimp*1)*(1e-6)*(1e-6);
I(2,2) = I(2,2) + (sigma*Eimp*1)*(1e-6)*(1e-6);
I(3,3) = I(3,3) + (sigma*Eimp*1)*(1e-6)*(1e-6);
I(4,4) = I(4,4) + (sigma*Eimp*1)*(1e-6)*(11e-6);

Z = V*inv(I);
Z11(io) = Z(1,1);
Z13(io) = Z(1,3);

fprintf('Now finished solving freq %f\n',omega(io));

end
figure(1);
semilogx(omega, real(Z11),'b--','linewidth',2);
hold on
semilogx(omega, real(Z13), 'k--', 'linewidth',2);
xlabel('Frequency (Hz)');
ylabel('Resistance');
legend('Z11','Z13')

%plot z
for is = 1:4
figure;
trisurf(element_nodeT,node_xT(:,1),node_xT(:,2),abs(1i*omega*u(:,is)));
colorbar; 
shading interp
axis([0 35e-6 0 24e-6])
xlabel('x');
ylabel('y');
title('2D FEM solution');
end




