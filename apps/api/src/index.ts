import { app } from './app';
import { getEnv } from './config/env';

const { PORT } = getEnv();

app.listen(PORT, () => {
  console.log(`API listening on port ${PORT}`);
});
