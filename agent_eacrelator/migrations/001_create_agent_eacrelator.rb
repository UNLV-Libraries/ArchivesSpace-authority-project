require 'db/migrations/utils'
Sequel.migration do
    up do
	  alter_table(:related_agents_rlshp) do
		add_column(:agent_eacrelator, String, :null => true, :default => nil) 
	  end
      create_editable_enum('agent_eacrelator', ["acquaintanceOf","ambivalentOf","ancestorOf","antagonistOf","apprenticeTo","childOf",
												"closeFriendOf","collaboratesWith","colleagueOf","descendantOf","employedBy","employerOf", "enemyOf",
												"engagedTo","friendOf","grandchildOf","grandparentOf","hasMet","influencedBy","knowsByReputation",
												"knowsInPassing","knowsOf","lifePartnerOf","livesWith","lostContactWith","mentorOf","neighborOf",
												"parentOf","participant","participantIn","relationship","siblingOf","spouseOf","worksWith","wouldLikeToKnow"])

    end
	down do	
		alter_table(:related_agents_rlshp) do
			drop_column(:agent_eacrelator)
		end
	end
end