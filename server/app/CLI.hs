module CLI (runCLI) where

-- Lấy danh sách các tham số và xử lý chúng
runCLI :: [String] -> IO ()
runCLI args =
  case head args of
    "migrate" -> do
      putStrLn "Running database migrations..."
      -- Thêm logic chạy migration ở đây
      putStrLn "Migrations complete."
    "reset-db" -> do
      putStrLn "Resetting database..."
      -- Thêm logic reset DB ở đây
      putStrLn "Database reset."
    _ ->
      putStrLn $ "Unknown command: " ++ head args