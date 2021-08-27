
# kubeflow-mnist

## Running Locally

Requires horizon-cli-2.28.0-338.x86_64.rpm added to the root of the project.

Verify you docker has over 3 GB memory
```
docker info  | grep Memory
 Total Memory: 3.844GiB
```

Install the Conda environment:

```sh
conda env create -f environment.yml
```

Then run training:

```sh
% python preprocessing.py --data_dir data
% python train.py --data_dir data --model_path export
```

## Building the image

DOCKER_BUILDKIT=1 docker build -t dcavanau/kubeflow-mnist env -f Dockerfile

## Tensorflow Serving

docker run -t --rm -p 8501:8501 \
    -v "$PWD/export:/models/mnist" \
    -e MODEL_NAME=mnist \
    tensorflow/serving:2.4.2
