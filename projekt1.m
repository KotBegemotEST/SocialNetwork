% Mudeli parameetrid
numNodes = 40; % Sõlmede arv
numScenarios = 3; % Stsenaariumide arv
numStates = 3; % Sõlme olekute arv (1: neutraalne, 2: tõene info, 3: valeinfo)
numDays = 20; % Päevade arv (suurendatud)
numLeadersSet = [1, 3, 5]; % Erinev arv arvamusliidreid
infectionProbability = 0.1; % Väiksem nakatumise tõenäosus
leaderInfluenceProbability = 0.05; % Kaitsetõenäosus nakatumise vastu arvamusliidri korral

% Oleku värvide määramine
colors = [0 0 1; 0 1 0; 1 0 0]; % Sinine, roheline, punane

% Juhusliku sotsiaalvõrgustiku genereerimine
adjMatrix = randi([0, 1], numNodes, numNodes);
adjMatrix = triu(adjMatrix, 1) + triu(adjMatrix, 1)'; % Sümmeetriline maatriks

% Algsete graafide visualiseerimine
figure('Name', 'Algsed graafid stsenaariumide jaoks');
for scenario = 1:numScenarios
    % Sõlmede algolek
    states = randi([1, numStates], numNodes, 1);
    
    % Stsenaariumide realiseerimine
    if scenario == 2
        % Stsenaarium 2: Valeinfo liidrid
        clusterNodes = randperm(numNodes, 5); % 5 nakatunud sõlme
        states(:) = 1; % Kõik sõlmed neutraalsed
        states(clusterNodes) = 3;

        % Tõese info liidrite lisamine
        leaderNodes = randperm(numNodes, 1); % 3 juhuslikku liidrit
        states(leaderNodes) = 2; % Rohelised sõlmed (arvamusliidrid)

    elseif scenario == 3
        % Stsenaarium 3: Lokaliseeritud nakkus
        clusterNodes = 1:10; % Esimene klaster nakatunud
        states(:) = 1; % Kõik sõlmed neutraalsed
        states(clusterNodes) = 3; % Klaster nakatunud

         % Tõese info liidrite lisamine
        leaderNodes = randperm(numNodes, 1); % 3 juhuslikku liidrit
        states(leaderNodes) = 2; % Rohelised sõlmed (arvamusliidrid)
    end
    
    % Graafi loomine
    subplot(1, 3, scenario);
    G = graph(adjMatrix);
    plot(G, 'NodeCData', states, 'Layout', 'force');
    colormap(colors);
    title(sprintf('Stsenaarium %d: Algolek', scenario));
    colorbar('Ticks', [1, 2, 3], 'TickLabels', {'Neutraalne', 'Tõene', 'Vale'});
end

% Nakkuse dünaamika erineva arvamusliidrite arvu korral
results = zeros(numDays, numel(numLeadersSet), numScenarios);

for i = 1:numel(numLeadersSet)
    numLeaders = numLeadersSet(i); % Hetke arvamusliidrite arv
    for scenario = 1:numScenarios
        % Sõlmede algolek
        states = randi([1, numStates], numNodes, 1);
        
        % Stsenaariumide realiseerimine
        if scenario == 2
            % Valeinfo liidrid
            clusterNodes = randperm(numNodes, 5);
            states(clusterNodes) = 3;
        elseif scenario == 3
            % Lokaliseeritud nakkus
            clusterNodes = 1:10;
            states(:) = 1;
            states(clusterNodes) = 3;
        end
        
        % Arvamusliidrite lisamine
        leaderNodes = randperm(numNodes, numLeaders);
        states(leaderNodes) = 2; % Tõese info liidrid
        
        % Simulatsioon päevade kaupa
        for day = 1:numDays
            newStates = states;
            for node = 1:numNodes
                if states(node) == 3 % Valeinfo sõlm
                    neighbors = find(adjMatrix(node, :) == 1); % Naabrid
                    for neighbor = neighbors
                        if states(neighbor) == 1 % Neutraalne sõlm
                            % Kontrollitakse liidri olemasolu naabrite seas
                            leaderNeighbors = find(adjMatrix(neighbor, :) == 1 & states == 2);
                            if isempty(leaderNeighbors) % Naabrite seas pole liidreid
                                if rand < infectionProbability
                                    newStates(neighbor) = 3; % Neutraalse nakatumine
                                end
                            else % Naabrite seas on liidreid
                                if rand < leaderInfluenceProbability % Väiksem nakatumise tõenäosus
                                    newStates(neighbor) = 3; % Neutraalse nakatumine
                                end
                            end
                        elseif states(neighbor) == 2
                            % Liider jääb muutumatuks
                            newStates(neighbor) = 2;
                        end
                    end
                end
            end
            states = newStates;
            results(day, i, scenario) = sum(states == 3); % Salvestatakse andmed
        end
    end
end

% Graafik 1: Nakkuse dünaamika erineva arvamusliidrite arvu korral
figure('Name', 'Nakkuse dünaamika');
for scenario = 1:numScenarios
    subplot(1, 3, scenario);
    hold on;
    for i = 1:numel(numLeadersSet)
        plot(1:numDays, results(:, i, scenario), 'LineWidth', 2, ...
            'DisplayName', sprintf('%d liidrit', numLeadersSet(i)));
    end
    title(sprintf('Stsenaarium %d', scenario));
    xlabel('Päevad');
    ylabel('Nakatunud sõlmede arv');
    legend;
    grid on;
    hold off;
end

% Graafik 2: Lõplik kaitse nakatumise eest
figure('Name', 'Lõplik kaitse nakatumise eest');
for scenario = 1:numScenarios
    subplot(1, 3, scenario);
    finalInfected = squeeze(results(end, :, scenario));
    bar(numLeadersSet, finalInfected);
    title(sprintf('Stsenaarium %d', scenario));
    xlabel('Liidrite arv');
    ylabel('Lõplik nakatunud arv');
    grid on;
end
