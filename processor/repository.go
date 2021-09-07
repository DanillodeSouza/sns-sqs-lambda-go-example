package processor

// Example
type Example interface {
	indexCVByUserID(userID int) (rerr error)
}

// ExampleImpl struct implements repository requirements
type ExampleImpl struct {
	config Config
}

// NewExampleRepository creates a new repository
func NewExampleRepository(config Config) *ExampleImpl {
	return &ExampleImpl{
		config: config,
	}
}

func (r ExampleImpl) Get(data map[string]interface{}) (response map[string]interface{}, err error) {
	//http request

	return data, nil
}
