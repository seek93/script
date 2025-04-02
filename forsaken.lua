			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(1, -20, 0, 25)
			TitleLabel.Position = UDim2.new(0, 10, 0, 10)
			TitleLabel.Text = title
			TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.TextSize = 16
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = Frame

			local MessageLabel = Instance.new("TextLabel")
			MessageLabel.Size = UDim2.new(1, -20, 0, 35)
			MessageLabel.Position = UDim2.new(0, 10, 0, 35)
			MessageLabel.Text = message
			MessageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			MessageLabel.BackgroundTransparency = 1
			MessageLabel.TextSize = 14
			MessageLabel.Font = Enum.Font.Gotham
			MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
			MessageLabel.TextWrapped = true
			MessageLabel.Parent = Frame

			Frame.Position = UDim2.new(1, 20, 0, 20 + (NotificationeIndexirus * 90))
			Frame:TweenPosition(UDim2.new(1, -290, 0, 20 + (NotificationeIndexirus * 90)), "Out", "Quad", 0.5)

			task.delay(duration, function()
				Frame:TweenPosition(UDim2.new(1, 20, 0, 20 + (NotificationeIndexirus * 90)), "Out", "Quad", 0.5)
				task.delay(0.5, function()
					ScreenGui:Destroy()
					Notificationes = Notificationes - 1
				end)
			end)

			return ScreenGui
		end

		MakeNotificatione("Welcome", "Script access valid! Loading script...", 3)
		task.delay(0.5, function()
			local timeLeftSecs = status.data.auth_expire - os.time()
			local hours = math.floor(timeLeftSecs / 3600)
			local minutes = math.floor((timeLeftSecs % 3600) / 60)
			MakeNotificatione("Subscription Info", "Time left: " .. hours .. "h " .. minutes .. "m", 4)
		end)
		task.delay(1, function()
			MakeNotificatione("Usage Stats", "Total executions: " .. status.data.total_executions, 4)
		end)
	else
		print(STATUS_MESSAGES[status.code] or status.message)
		makeUI()
	end
else
	makeUI()
end

while ApiStatusCode ~= "KEY_VALID" do task.wait(.1) end
script_key = sigmakey
api.load_script()
